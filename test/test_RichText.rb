#
# test_RichText.rb - TaskJuggler
#
# Copyright (c) 2006, 2007 by Chris Schlaeger <cs@kde.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'RichText'

class TestRichText < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_paragraph
    inp = <<'EOT'
A paragraph may span multiple
lines of text. Single line breaks
are ignored.


Only 2 successive newlines end the paragraph.

I hope this example is
clear
now.
EOT

    # Check tagged output.
    out = newRichText(inp).to_tagged + "\n"
    ref = <<'EOT'
<div><p>[A] [paragraph] [may] [span] [multiple] [lines] [of] [text.] [Single] [line] [breaks] [are] [ignored.]</p>

<p>[Only] [2] [successive] [newlines] [end] [the] [paragraph.]</p>

<p>[I] [hope] [this] [example] [is] [clear] [now.]</p>

</div>
EOT
    assert_equal(out, ref)

    # Check ASCII output.
    out = newRichText(inp).to_s
    ref = <<'EOT'
A paragraph may span multiple lines of text. Single line breaks are ignored.

Only 2 successive newlines end the paragraph.

I hope this example is clear now.

EOT
    assert_equal(out, ref)

    # Check HTML output.
    out = newRichText(inp).to_html.to_s + "\n"
    ref = <<'EOT'
<div>
 <p>A paragraph may span multiple lines of text. Single line breaks are ignored.</p>
 <p>Only 2 successive newlines end the paragraph.</p>
 <p>I hope this example is clear now.</p>
</div>
EOT
    assert_equal(out, ref)
  end

  def test_hline
    inp = <<'EOT'
----
Line above and below
----
== A heading ==
----

----
----
Another bit of text.
----
EOT

    # Check tagged output.
    out = newRichText(inp).to_tagged + "\n"
    ref = <<'EOT'
<div><hr>----</hr>
<p>[Line] [above] [and] [below]</p>

<hr>----</hr>
<h1>1 [A] [heading]</h1>

<hr>----</hr>
<hr>----</hr>
<hr>----</hr>
<p>[Another] [bit] [of] [text.]</p>

<hr>----</hr>
</div>
EOT
    assert_equal(out, ref)

    # Check ASCII output.
    rt = newRichText(inp)
    rt.lineWidth = 60
    out = rt.to_s
    ref = <<'EOT'
--------------------------------------------------------
Line above and below

--------------------------------------------------------
1 A heading

--------------------------------------------------------
--------------------------------------------------------
--------------------------------------------------------
Another bit of text.

--------------------------------------------------------
EOT
    assert_equal(out, ref)

    # Check HTML output.
    out = newRichText(inp).to_html.to_s + "\n"
    ref = <<'EOT'
<div>
 <hr/>
 <p>Line above and below</p>
 <hr/>
 <h1 id="A_heading">1 A heading</h1>
 <hr/>
 <hr/>
 <hr/>
 <p>Another bit of text.</p>
 <hr/>
</div>
EOT
    assert_equal(out, ref)
  end

  def test_italic
    inp = "This is a text with ''italic words'' in it."

    # Check tagged output.
    out = newRichText(inp).to_tagged + "\n"
    ref = <<'EOT'
<div>[This] [is] [a] [text] [with] <i>[italic] [words]</i> [in] [it.]</div>
EOT
    assert_equal(out, ref)

    # Check ASCII output.
    rt = newRichText(inp)
    out = rt.to_s + "\n"
    ref = <<'EOT'
This is a text with italic words in it.
EOT
    assert_equal(out, ref)

    # Check HTML output.
    out = newRichText(inp).to_html.to_s + "\n"
    ref = <<'EOT'
<div>This is a text with <i>italic words</i> in it.</div>
EOT
    assert_equal(out, ref)
  end

  def test_bold
    inp = "This is a text with '''bold words''' in it."

    # Check tagged output.
    out = newRichText(inp).to_tagged + "\n"
    ref = <<'EOT'
<div>[This] [is] [a] [text] [with] <b>[bold] [words]</b> [in] [it.]</div>
EOT
    assert_equal(out, ref)

    # Check ASCII output.
    rt = newRichText(inp)
    out = rt.to_s + "\n"
    ref = <<'EOT'
This is a text with bold words in it.
EOT
    assert_equal(out, ref)

    # Check HTML output.
    out = newRichText(inp).to_html.to_s + "\n"
    ref = <<'EOT'
<div>This is a text with <b>bold words</b> in it.</div>
EOT
    assert_equal(out, ref)
  end

  def test_code
    inp = "This is a text with ''''monospaced words'''' in it."

    # Check tagged output.
    out = newRichText(inp).to_tagged + "\n"
    ref = <<'EOT'
<div>[This] [is] [a] [text] [with] <code>[monospaced] [words]</code> [in] [it.]</div>
EOT
    assert_equal(out, ref)

    # Check ASCII output.
    rt = newRichText(inp)
    out = rt.to_s + "\n"
    ref = <<'EOT'
This is a text with monospaced words in it.
EOT
    assert_equal(out, ref)

    # Check HTML output.
    out = newRichText(inp).to_html.to_s + "\n"
    ref = <<'EOT'
<div>This is a text with <code>monospaced words</code> in it.</div>
EOT
    assert_equal(out, ref)
  end

  def test_boldAndItalic
    inp = <<'EOT'
This is a text with some '''bold words''', some ''italic'' words and some
'''''bold and italic''''' words in it.
EOT

    # Check tagged output.
    out = newRichText(inp).to_tagged + "\n"
    ref = <<'EOT'
<div>[This] [is] [a] [text] [with] [some] <b>[bold] [words]</b>[,] [some] <i>[italic]</i> [words] [and] [some] <b><i>[bold] [and] [italic]</i></b> [words] [in] [it.]</div>
EOT
    assert_equal(out, ref)

    # Check ASCII output.
    rt = newRichText(inp)
    out = rt.to_s + "\n"
    ref = <<'EOT'
This is a text with some bold words, some italic words and some bold and italic words in it.
EOT
    assert_equal(out, ref)

    # Check HTML output.
    out = newRichText(inp).to_html.to_s + "\n"
    ref = <<'EOT'
<div>This is a text with some <b>bold words</b>, some <i>italic</i> words and some <b><i>bold and italic</i></b> words in it.</div>
EOT
    assert_equal(out, ref)
  end

  def test_ref
    inp = <<'EOT'
This is a reference [[item]].
For more info see [[manual the user manual]].
EOT

    # Check tagged output.
    out = newRichText(inp).to_tagged + "\n"
    ref = <<'EOT'
<div>[This] [is] [a] [reference] <ref data="item">[item]</ref>[.] [For] [more] [info] [see] <ref data="manual">[the user manual]</ref>[.]</div>
EOT
    assert_equal(out, ref)

    # Check ASCII output.
    rt = newRichText(inp)
    out = rt.to_s + "\n"
    ref = <<'EOT'
This is a reference item. For more info see the user manual.
EOT
    assert_equal(out, ref)

    # Check HTML output.
    out = newRichText(inp).to_html.to_s + "\n"
    ref = <<'EOT'
<div>This is a reference <a href="item.html">item</a>. For more info see <a href="manual.html">the user manual</a>.</div>
EOT
    assert_equal(out, ref)
  end

  def test_href
    inp = <<'EOT'
This is a reference [http://www.taskjuggler.org].
For more info see [[http://www.taskjuggler.org the TaskJuggler site]].
EOT

    # Check tagged output.
    out = newRichText(inp).to_tagged + "\n"
    ref = <<'EOT'
<div>[This] [is] [a] [reference] <a href="http://www.taskjuggler.org">[http://www.taskjuggler.org]</a>[.] [For] [more] [info] [see] <ref data="http://www.taskjuggler.org">[the TaskJuggler site]</ref>[.]</div>
EOT
    assert_equal(out, ref)

    # Check ASCII output.
    rt = newRichText(inp)
    out = rt.to_s + "\n"
    ref = <<'EOT'
This is a reference http://www.taskjuggler.org. For more info see the TaskJuggler site.
EOT
    assert_equal(out, ref)

    # Check HTML output.
    out = newRichText(inp).to_html.to_s + "\n"
    ref = <<'EOT'
<div>This is a reference <a href="http://www.taskjuggler.org">http://www.taskjuggler.org</a>. For more info see <a href="http://www.taskjuggler.org.html">the TaskJuggler site</a>.</div>
EOT
    assert_equal(out, ref)
  end

  def test_headline
    inp = <<'EOT'
= This is not a headline
== This is level 1 ==
=== This is level 2 ===
==== This is level 3 ====
EOT

    # Check tagged output.
    out = newRichText(inp).to_tagged + "\n"
    ref = <<'EOT'
<div><p>[=] [This] [is] [not] [a] [headline]</p>

<h1>1 [This] [is] [level] [1]</h1>

<h2>1.1 [This] [is] [level] [2]</h2>

<h3>1.1.1 [This] [is] [level] [3]</h3>

</div>
EOT
    assert_equal(out, ref)

    # Check ASCII output.
    rt = newRichText(inp)
    out = rt.to_s
    ref = <<'EOT'
= This is not a headline

1 This is level 1

1.1 This is level 2

1.1.1 This is level 3

EOT
    assert_equal(out, ref)

    # Check HTML output.
    out = newRichText(inp).to_html.to_s + "\n"
    ref = <<'EOT'
<div>
 <p>= This is not a headline</p>
 <h1 id="This_is_level_1">1 This is level 1</h1>
 <h2 id="This_is_level_2">1.1 This is level 2</h2>
 <h3 id="This_is_level_3">1.1.1 This is level 3</h3>
</div>
EOT
    assert_equal(out, ref)
  end

  def test_bullet
    inp = <<'EOT'
* This is a bullet item
** This is a level 2 bullet item
*** This is a level 3 bullet item
EOT

    # Check tagged output.
    out = newRichText(inp).to_tagged + "\n"
    ref = <<'EOT'
<div><ul><li>* [This] [is] [a] [bullet] [item]</li>
<ul><li> * [This] [is] [a] [level] [2] [bullet] [item]</li>
<ul><li>  * [This] [is] [a] [level] [3] [bullet] [item]</li>
</ul></ul></ul></div>
EOT
    assert_equal(out, ref)

    # Check ASCII output.
    rt = newRichText(inp)
    out = rt.to_s + "\n"
    ref = <<'EOT'
* This is a bullet item

 * This is a level 2 bullet item

  * This is a level 3 bullet item


EOT
    assert_equal(out, ref)

    # Check HTML output.
    out = newRichText(inp).to_html.to_s + "\n"
    ref = <<'EOT'
<div><ul>
  <li>This is a bullet item</li>
  <ul>
   <li>This is a level 2 bullet item</li>
   <ul><li>This is a level 3 bullet item</li></ul>
  </ul>
 </ul></div>
EOT
    assert_equal(out, ref)
  end

  def test_number
    inp = <<'EOT'
# This is item 1
# This is item 2
# This is item 3

Normal text.

# This is item 1
## This is item 1.1
## This is item 1.2
## This is item 1.3
# This is item 2
## This is item 2.1
## This is item 2.2
### This is item 2.2.1
### This is item 2.2.2
# This is item 3
## This is item 3.1
### This is item 3.1.1
# This is item 4
### This is item 4.0.1

Normal text.

# This is item 1
EOT

    # Check tagged output.
    out = newRichText(inp).to_tagged + "\n"
    ref = <<'EOT'
<div><ol><li>1 [This] [is] [item] [1]</li>
<li>2 [This] [is] [item] [2]</li>
<li>3 [This] [is] [item] [3]</li>
</ol><p>[Normal] [text.]</p>

<ol><li>1 [This] [is] [item] [1]</li>
<ol><li>1.1 [This] [is] [item] [1.1]</li>
<li>1.2 [This] [is] [item] [1.2]</li>
<li>1.3 [This] [is] [item] [1.3]</li>
</ol><li>2 [This] [is] [item] [2]</li>
<ol><li>2.1 [This] [is] [item] [2.1]</li>
<li>2.2 [This] [is] [item] [2.2]</li>
<ol><li>2.2.1 [This] [is] [item] [2.2.1]</li>
<li>2.2.2 [This] [is] [item] [2.2.2]</li>
</ol></ol><li>3 [This] [is] [item] [3]</li>
<ol><li>3.1 [This] [is] [item] [3.1]</li>
<ol><li>3.1.1 [This] [is] [item] [3.1.1]</li>
</ol></ol><li>4 [This] [is] [item] [4]</li>
<ol><ol><li>4.0.1 [This] [is] [item] [4.0.1]</li>
</ol></ol></ol><p>[Normal] [text.]</p>

<ol><li>1 [This] [is] [item] [1]</li>
</ol></div>
EOT
    assert_equal(out, ref)

    # Check ASCII output.
    rt = newRichText(inp)
    out = rt.to_s + "\n"
    ref = <<'EOT'
1 This is item 1

2 This is item 2

3 This is item 3

Normal text.

1 This is item 1

1.1 This is item 1.1

1.2 This is item 1.2

1.3 This is item 1.3

2 This is item 2

2.1 This is item 2.1

2.2 This is item 2.2

2.2.1 This is item 2.2.1

2.2.2 This is item 2.2.2

3 This is item 3

3.1 This is item 3.1

3.1.1 This is item 3.1.1

4 This is item 4

4.0.1 This is item 4.0.1

Normal text.

1 This is item 1


EOT
    assert_equal(out, ref)

    # Check HTML output.
    out = newRichText(inp).to_html.to_s + "\n"
    ref = <<'EOT'
<div>
 <ol>
  <li>This is item 1</li>
  <li>This is item 2</li>
  <li>This is item 3</li>
 </ol>
 <p>Normal text.</p>
 <ol>
  <li>This is item 1</li>
  <ol>
   <li>This is item 1.1</li>
   <li>This is item 1.2</li>
   <li>This is item 1.3</li>
  </ol>
  <li>This is item 2</li>
  <ol>
   <li>This is item 2.1</li>
   <li>This is item 2.2</li>
   <ol>
    <li>This is item 2.2.1</li>
    <li>This is item 2.2.2</li>
   </ol>
  </ol>
  <li>This is item 3</li>
  <ol>
   <li>This is item 3.1</li>
   <ol><li>This is item 3.1.1</li></ol>
  </ol>
  <li>This is item 4</li>
  <ol><ol><li>This is item 4.0.1</li></ol></ol>
 </ol>
 <p>Normal text.</p>
 <ol><li>This is item 1</li></ol>
</div>
EOT
    assert_equal(out, ref)
  end

  def test_pre
    inp = <<'EOT'
 #include <stdin.h>
 main() {
   printf("Hello, world!\n")
 }
EOT

    # Check tagged output.
    out = newRichText(inp).to_tagged + "\n"
    ref = <<'EOT'
<div><pre>#include <stdin.h>
main() {
  printf("Hello, world!\n")
}
</pre>

</div>
EOT
    assert_equal(out, ref)

    # Check ASCII output.
    rt = newRichText(inp)
    out = rt.to_s
    ref = <<'EOT'
#include <stdin.h>
main() {
  printf("Hello, world!\n")
}

EOT
    assert_equal(out, ref)

    # Check HTML output.
    out = newRichText(inp).to_html.to_s + "\n"
    ref = <<'EOT'
<div><pre>#include &lt;stdin.h&gt;
main() {
  printf("Hello, world!\n")
}
</pre></div>
EOT
    assert_equal(out, ref)
  end

  def test_mix
    inp = <<'EOT'
== This the first section ==
=== This is the section 1.1 ===

Not sure what to put here. Maybe
just some silly text.

* A bullet
** Another bullet
# A number item
* A bullet
## Number 0.1, I guess

== Section 2 ==
* Starts with bullets
* ...

Some more text. And we're done.
EOT

    # Check tagged output.
    out = newRichText(inp).to_tagged + "\n"
    ref = <<'EOT'
<div><h1>1 [This] [the] [first] [section]</h1>

<h2>1.1 [This] [is] [the] [section] [1.1]</h2>

<p>[Not] [sure] [what] [to] [put] [here.] [Maybe] [just] [some] [silly] [text.]</p>

<ul><li>* [A] [bullet]</li>
<ul><li> * [Another] [bullet]</li>
</ul></ul><ol><li>1 [A] [number] [item]</li>
</ol><ul><li>* [A] [bullet]</li>
</ul><ol><ol><li>0.1 [Number] [0.1,] [I] [guess]</li>
</ol></ol><h1>2 [Section] [2]</h1>

<ul><li>* [Starts] [with] [bullets]</li>
<li>* [...]</li>
</ul><p>[Some] [more] [text.] [And] [we're] [done.]</p>

</div>
EOT
    assert_equal(out, ref)

    # Check ASCII output.
    rt = newRichText(inp)
    out = rt.to_s
    ref = <<'EOT'
1 This the first section

1.1 This is the section 1.1

Not sure what to put here. Maybe just some silly text.

* A bullet

 * Another bullet

1 A number item

* A bullet

0.1 Number 0.1, I guess

2 Section 2

* Starts with bullets

* ...

Some more text. And we're done.

EOT
    assert_equal(out, ref)

    # Check HTML output.
    out = newRichText(inp).to_html.to_s + "\n"
    ref = <<'EOT'
<div>
 <h1 id="This_the_first_section">1 This the first section</h1>
 <h2 id="This_is_the_section_11">1.1 This is the section 1.1</h2>
 <p>Not sure what to put here. Maybe just some silly text.</p>
 <ul>
  <li>A bullet</li>
  <ul><li>Another bullet</li></ul>
 </ul>
 <ol><li>A number item</li></ol>
 <ul><li>A bullet</li></ul>
 <ol><ol><li>Number 0.1, I guess</li></ol></ol>
 <h1 id="Section_2">2 Section 2</h1>
 <ul>
  <li>Starts with bullets</li>
  <li>...</li>
 </ul>
 <p>Some more text. And we're done.</p>
</div>
EOT
    assert_equal(out, ref)
  end

  def test_nowiki
    inp = <<'EOT'
== This the first section ==
=== This is the section 1.1 ===

Not sure <nowiki>''what'' to</nowiki> put here. Maybe
just some silly text.

* A bullet
** Another bullet
# A number item
* A bullet<nowiki>
## Number 0.1, I guess
== Section 2 ==</nowiki>
* Starts with bullets
* ...

Some more text. And we're done.
EOT

    # Check tagged output.
    out = newRichText(inp).to_tagged + "\n"
    ref = <<'EOT'
<div><h1>1 [This] [the] [first] [section]</h1>

<h2>1.1 [This] [is] [the] [section] [1.1]</h2>

<p>[Not] [sure] [''what''] [to] [put] [here.] [Maybe] [just] [some] [silly] [text.]</p>

<ul><li>* [A] [bullet]</li>
<ul><li> * [Another] [bullet]</li>
</ul></ul><ol><li>1 [A] [number] [item]</li>
</ol><ul><li>* [A] [bullet]</li>
</ul><p>[##] [Number] [0.1,] [I] [guess]</p>

<p>[==] [Section] [2] [==]</p>

<ul><li>* [Starts] [with] [bullets]</li>
<li>* [...]</li>
</ul><p>[Some] [more] [text.] [And] [we're] [done.]</p>

</div>
EOT
    assert_equal(out, ref)

    # Check ASCII output.
    rt = newRichText(inp)
    out = rt.to_s
    ref = <<'EOT'
1 This the first section

1.1 This is the section 1.1

Not sure ''what'' to put here. Maybe just some silly text.

* A bullet

 * Another bullet

1 A number item

* A bullet

## Number 0.1, I guess

== Section 2 ==

* Starts with bullets

* ...

Some more text. And we're done.

EOT
    assert_equal(out, ref)

    # Check HTML output.
    out = newRichText(inp).to_html.to_s + "\n"
    ref = <<'EOT'
<div>
 <h1 id="This_the_first_section">1 This the first section</h1>
 <h2 id="This_is_the_section_11">1.1 This is the section 1.1</h2>
 <p>Not sure ''what'' to put here. Maybe just some silly text.</p>
 <ul>
  <li>A bullet</li>
  <ul><li>Another bullet</li></ul>
 </ul>
 <ol><li>A number item</li></ol>
 <ul><li>A bullet</li></ul>
 <p>## Number 0.1, I guess</p>
 <p>== Section 2 ==</p>
 <ul>
  <li>Starts with bullets</li>
  <li>...</li>
 </ul>
 <p>Some more text. And we're done.</p>
</div>
EOT
    assert_equal(out, ref)
  end

  def newRichText(text)
    begin
      rText = RichText.new(text)
    rescue RichTextException => msg
      $stderr.puts "Error in RichText Line #{msg.lineNo}: #{msg.text}\n" +
                   "#{msg.line}"
    end
    rText
  end

end