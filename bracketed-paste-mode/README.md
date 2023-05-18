<html>
<head>
  <!-- <title>Bracketed Paste Mode</title> -->
</head>
<body>
<h1>Bracketed Paste Mode</h1>
<p>
A one-liner that turns off <a href="https://en.wikipedia.org/wiki/Bracketed-paste">Bracketed Paste Mode</a>. Bracketed Paste Mode is an irritating "feature" that I have managed to avoid until recently. 
</p>

<p>
You notice that you are affected by bracketed paste mode by seeing <b><code>0~foo1~</code></b> instead of <b><code>foo</code></b> when you paste the string "foo". Actually it's not "0~" and "1~" that are added at the front and the end of the string, but rather the escape sequences "&lt;ESC&gt;[200~" and "&lt;ESC&gt;[201~" respectively.
</p>

<p>
Supposedly, bracketed paste mode was introduced in order to enable pasting of multi-line code snippets into user interfaces that auto-indent every time a line break is inserted. But it breaks the expectation that the paste operation should never insert any extra characters. The problems caused by auto-indent are easily solved by re-indenting the newly inserted region directly after the paste. In Emacs, this is done via the single command <b><code>C-M-\</code></b>. Of course, this only works in programming languages that have proper syntax for structural nesting, rather than abusing significant whitespace for this purpose. So if you program in Python, please use <a href="https://en.wikipedia.org/wiki/Hy">Hylang</a> instead of regular Python. If you must use regular Python, consider reverting to punched cards as the user interface, because punched cards is truly the appropriate technology when you have to deal with significant whitespace.
</p>

<p>
A simpler way to eliminate the problems caused by auto-indent is to turn it off. In Emacs this is done by adding the following to your <b><code>~/.emacs</code></b>:
</p>

<pre>
(electric-indent-mode -1)
</pre>

<p>
Now you'll have to press "&lt;TAB&gt;" to indent the next line, but this is hardly a huge burden.
</p>

<p>
You still have to disable Bracketed Paste Mode however, otherwise you will get extra characters inserted every time you paste.
</p>

<p>
Examples:
</p>

<pre>
./disable-bracketed-paste-mode
</pre>

Disables bracketed paste mode in the current terminal.
</body>
</html>
