#!/usr/bin/env ruby -w
# encoding: UTF-8
#
# = ProjectBroker.rb -- The TaskJuggler III Project Management Software
#
# Copyright (c) 2006, 2007, 2008, 2009, 2010 by Chris Schlaeger <cs@kde.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#

require 'monitor'
require 'thread'
require 'drb'
require 'drb/acl'
require 'daemon/Daemon'
require 'daemon/ProjectServer'
require 'TjTime'

class TaskJuggler

  # The ProjectBroker is the central object of the TaskJuggler daemon. It can
  # manage multiple scheduled projects that it keeps in separate sub
  # processes. Requests to a specific project will be redirected to the
  # specific ProjectServer process. Projects can be added or removed. Adding
  # an already existing one (identified by project ID) will replace the old
  # one as soon as the new one has been scheduled successfully.
  #
  # The daemon uses DRb to communicate with the client and it's sub processes.
  # The communication is restricted to localhost. All remote commands require
  # an authentication key.
  #
  # Currently only tj3client can be used to communicate with the TaskJuggler
  # daemon.
  class ProjectBroker < Daemon

    def initialize
      super
      # We don't have a default key. The user must provice a key in the config
      # file. Otherwise the daemon will not start.
      @authKey = nil
      # The default TCP/IP port. ASCII decimal codes for 'T' and 'J'.
      @port = 8474
      # A list of loaded projects as Array of ProjectRecord objects.
      @projects = []
      # We operate with multiple threads so we need a Monitor to synchronize
      # the access to the list.
      @projects.extend(MonitorMixin)

      # This Queue is used to load new projects. The DRb thread pushes load
      # requests that the housekeeping thread will then perform.
      @projectsToLoad = Queue.new

      # This flag will be set to true to terminate the daemon.
      @terminate = false
    end

    def start(projects)
      # To ensure a certain level of security, the user must provide an
      # authentication key to authenticate the client to this server.
      unless @authKey
        @log.fatal(<<'EOT'
You must set an authentication key in the configuration file. Create a file
named .taskjugglerrc or taskjuggler.rc that contains at least the following
lines. Replace 'your_secret_key' with some random character sequence.

_global:
  authKey: your_secret_key
EOT
                  )
      end

      super()
      @log.debug("Starting project broker")

      # Setup a DRb server to handle the incomming requests from the clients.
      brokerIface = ProjectBrokerIface.new(self)
      begin
        $SAFE = 1
        DRb.install_acl(ACL.new(%w[ deny all
                                    allow localhost ]))
        @uri = DRb.start_service("druby://localhost:#{@port}", brokerIface).uri
        @log.info("TaskJuggler daemon is listening on #{@uri}")
      rescue
        @log.fatal("Cannot listen on port #{@port}: #{$!}")
      end

      # If project files were specified on the command line, we add them here.
      i = 0
      projects.each do |project|
        @projectsToLoad.push([ i += 1, project ])
      end

      # Start a Thread that waits for the @terminate flag to be set and does
      # some other work asynchronously.
      startHousekeeping

      # Cleanup the DRb threads
      DRb.thread.join
      @log.info('TaskJuggler daemon terminated')
    end

    # All remote commands must provide the proper authentication key. Usually
    # the client and the server get this secret key from the same
    # configuration file.
    def checkKey(authKey, command)
      if authKey == @authKey
        @log.debug("Accepted authentication key for command '#{command}'")
      else
        @log.warning("Rejected wrong authentication key #{authKey} " +
                     "for command '#{command}'")
        return false
      end
      true
    end

    # This command will initiate the termination of the daemon.
    def stop
      @log.debug('Terminating on client request')

      # Send termination signal to all ProjectServer instances
      @projects.synchronize do
        @projects.each { |p| p.terminateServer }
      end

      # Setting the @terminate flag to true will case the terminator Thread to
      # call DRb.stop_service
      @terminate = true
      super
    end

    # Generate a table with information about the loaded projects.
    def status
      if @projects.empty?
        "No projects registered\n"
      else
        out = ''
        @projects.synchronize do
          @projects.each do |project|
            out += project.to_s
          end
        end
        out
      end
    end

    # Adding a new project or replacing an existing one. _args_ is an Array of
    # Strings. The first element is the working directory. The second one is
    # the master project file (.tjp file). Additionally a list of optional
    # .tji files can be provided. The command waits until the project has been
    # loaded or the load has failed.
    def addProject(args)
      # We need some tag to identify the ProjectRecord that this project was
      # associated to. Just use a large enough random number.
      tag = rand(9999999999999)

      @log.debug("Pushing #{tag} to load Queue")
      @projectsToLoad.push([ tag, args ])

      # Now we have to wait until the loaded project shows up in the @projects
      # list. We use our tag to identify the right entry.
      pr = nil
      while pr.nil?
        @projects.synchronize do
          @projects.each do |p|
            if p.tag == tag
              pr = p
              break
            end
          end
        end
        # The wait in this loop should be pretty short and we don't want to
        # miss IO from the ProjectServer process.
        sleep 0.1 unless pr
      end

      @log.debug("Found tag #{tag} in list of loaded projects with URI " +
                 "#{pr.uri}")
      # Return the URI and the authentication key of the new ProjectServer.
      [ pr.uri, pr.authKey ]
    end

    def removeProject(args)
      # Find all projects with the IDs in args and mark them as :obsolete.
      @projects.synchronize do
        @projects.each do |p|
          p.state = :obsolete if args.include?(p.id)
        end
      end
    end

    def getProject(projectId)
      # Find the project with the ID args[0].
      project = nil
      @projects.synchronize do
        @projects.each do |p|
          project = p if p.id == projectId && p.state == :ready
        end
      end

      if project.nil?
        @log.debug("No project with ID #{projectId} found")
        return [ nil, nil ]
      end
      [ project.uri, project.authKey ]
    end

    def updateState(authKey, id, state)
      result = false
      @projects.synchronize do
        @projects.each do |project|
          # Don't accept updates for already obsolete entries.
          next if project.state == :obsolete

          @log.debug("Updating state for #{authKey} to #{state}")
          # Only update the record that has the matching authKey
          if project.authKey == authKey
            project.id = id

            # If the state is being changed from something to :ready, this is
            # now the current project for the project ID.
            if state == :ready && project.state != :ready
              # Mark other project records with same project ID as obsolete
              @projects.each do |p|
                if p != project && p.id == id
                  p.state = :obsolete
                  @log.debug("Marking entry with ID #{id} as obsolete")
                end
              end
              project.readySince = TjTime.now
            end

            project.state = state
            result = true
            break
          end
        end
      end

      result
    end

    private

    def startHousekeeping
      Thread.new do
        loop do
          if @terminate
            # Give the caller a chance to properly terminate the connection.
            sleep 1
            @log.debug('Shutting down DRb server')
            DRb.stop_service
            break
          elsif !@projectsToLoad.empty?
            loadProject(@projectsToLoad.pop)
          else
            # Send termination command to all obsolute ProjectServer objects.
            # To minimize the locking of @projects we collect the obsolete
            # items first.
            termList = []
            @projects.synchronize do
              @projects.each do |p|
                termList << p if p.state == :obsolete
              end
            end
            # And then send them a termination command.
            termList.each { |p| p.terminateServer }

            # The housekeeping thread rarely needs to so something. Make sure
            # it's sleeping most of the time.
            sleep 1

            # Remove the obsolete records from the @projects list.
            @projects.synchronize do
              @projects.delete_if { |p| termList.include?(p) }
            end
          end
        end
      end
    end

    def loadProject(xargs)
      tag = xargs[0]
      args = xargs[1]
      @log.debug("Loading project #{args.join(' ')}")
      pr = ProjectRecord.new(tag)
      ps = ProjectServer.new(args)
      # The ProjectServer can be reached via this DRb URI
      pr.uri = ps.uri
      # Method calls must be authenticated with this key
      pr.authKey = ps.authKey

      # Add the ProjectRecord to the @projects list
      @projects.synchronize do
        @projects << pr
      end
    end

  end

  class ProjectBrokerIface

    def initialize(broker)
      @broker = broker
    end

    def apiVersion(authKey, version)
      return 0 unless @broker.checkKey(authKey, 'apiVersion')

      version == 1 ? 1 : -1
    end

    def command(authKey, cmd, args)
      return false unless @broker.checkKey(authKey, cmd)

      case cmd
      when :status
        @broker.status
      when :stop
        @broker.stop
      when :addProject
        @broker.addProject(args)
      when :removeProject
        @broker.removeProject(args)
      when :getProject
        @broker.getProject(args)
      end
    end

    def updateState(authKey, id, status)
      @broker.updateState(authKey, id, status)
    end

  end

  class ProjectRecord < Monitor

    attr_accessor :authKey, :uri, :id, :state, :readySince
    attr_reader :tag

    def initialize(tag)
      @tag = tag
      @authKey = nil
      @uri = nil
      @id = nil
      @state = :loading
      @readySince = nil
    end

    def terminateServer
      return unless @uri

      log = LogFile.instance
      begin
        if (projectServer = DRbObject.new(nil, @uri))
          log.debug("Sending termination request to ProcessServer " +
                    "#{@uri}")
          projectServer.terminate(@authKey)
        end
      rescue
        log.error("Termination of ProjectServer failed: #{$!}")
      end
      @uri = nil
    end

    def to_s
      out = "#{@id}: #{@state}"
      out += " #{@readySince}" if @readySince
      out += "\n"
    end

  end

end
