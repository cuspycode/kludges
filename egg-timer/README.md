<html>
<head>
  <!-- <title>Yet Another Egg Timer</title> -->
</head>
<body>
<h1>Yet Another Egg Timer</h1>
I realized that I have never implemented an Egg Timer, so I quickly programmed a shell script to do that.
It takes two arguments: &lt;MINUTES&gt; &lt;SECONDS&gt;. The &lt;SECONDS&gt; argument is optional.
It also checks the environment variable $TIMERHOOK and executes it as a command when the time is up.
The resolution is about one second, since the script sleeps one second at a time. It uses the command "date +%s" to keep track of the remaining time to wait, so it will automatically adjust its timing if the sleep commands take longer or shorter than one second (try pressing ^S and ^Q to see how that works). When the time is up, the terminal window will invert its foreground and background colors and prompt for a carriage return. This requires a VT100-compatible terminal window.

<p>
Examples:

<pre>
timer.sh 3 14
</pre>

Counts down from 3 minutes and 14 seconds.

<pre>
TIMERHOOK="/bin/echo -e '\007'" timer.sh 0 45
</pre>

Counts down 45 seconds and rings the bell.

<pre>
TIMERHOOK="say Your tea is ready" timer.sh 2 30
</pre>

On macOS: Counts down 2 minutes and 30 seconds and uses the built-in voice synthesizer to say "Your tea is ready."

</body>
</html>
