<HTML>
<HEAD>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset="ISO-8859-1">
<TITLE>buffer.c</TITLE>
<LINK REL=StyleSheet HREF="../style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY>
<H1>buffer.c</H1>
<P>
This program reads data from standard input, buffers it, then writes it to
standard output. The default buffer size is 4 Mbytes (4194304 bytes in this
case, not 4000000). Call it as <B>buffer 42</B> to use a 42 Mbyte buffer.
I use this program to buffer the PCM data extracted from
RealAudio<FONT SIZE=-1><SUP>TM</SUP></FONT>
crap before feeding it to an MP3 encoder.

<P>
Implemented by a simple select() loop and a ring of buffers.

<P>
Source code: <A HREF="buffer.c">buffer.c</A>.<BR>
Compile like this: <CODE><B>gcc -O3 -o buffer buffer.c</B></CODE><BR>
How to reduce the verbosity level: <CODE><B>buffer 2>/dev/null</B></CODE>

<P>
Typical use:

<PRE>
URL=rtsp://www.example.com/encoder/1729.rm
MINUTES=60

mkfifo audiodump.wav
buffer < audiodump.wav | lame --quiet -b 128 - foo.mp3 &
(sleep `expr $MINUTES \* 60`; echo "quit") | \
        mplayer -really-quiet -ao pcm -vc dummy -vo null \
                -slave -cache 500 $URL

</PRE>
<HR>

</BODY>
</HTML>
