<HTML>
<HEAD>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset="ISO-8859-1">
<!-- <TITLE>proxy3.c</TITLE> -->
<LINK REL=StyleSheet HREF="../style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY>
<H1>proxy3.c</H1>
<P>
Forwards any remote TCP port to the local machine. Optionally logs the TCP
traffic to a file or to stdout. Optional authenticated mode requires a
simple cleartext password handshake to be negotiated before any TCP
connection is forwarded.

<P>
Source code: <A HREF="proxy3.c">proxy3.c</A>.<BR>
Compile like this: <CODE><B>gcc -O3 -o proxy3 proxy3.c</B></CODE><BR>
On Solaris you might need <CODE><B>-lnsl</B></CODE>, or maybe not any
more. I don't really know. I haven't tried compiling anything on Solaris
in the current century...

<P>
Typical use:

<PRE>
        proxy3 www.example.com 80 1080 -o nntp.log
	lynx http://localhost:1080/
</PRE>

<P>
Footnote: this was my first program ever that used the Unix socket
interface. I wrote it in order to learn this stuff, but also because
I needed the functionality, which I didn't know where to find back
then, in 1997. Nowadays I use SSH to forward ports of course, but on
occasion I crank up this old program and use it for debugging etc.

<HR>

</BODY>
</HTML>
