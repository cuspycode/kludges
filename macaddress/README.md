<HTML>
<HEAD>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset="ISO-8859-1">
<!-- <TITLE>macaddress.pl</TITLE> -->
<LINK REL=StyleSheet HREF="../style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY>
<H1>macaddress.pl</H1>
<P>
This perl script collects MAC addresses on a local ethernet-based IP network.
It does this by sending ICMP ECHO packets asynchronously to the specified
range of addresses, and then picks up the ARP cache by running
<CODE><B>arp -a</B></CODE> after waiting for replies.

<P>
If I recall correctly, this was the first program I wrote that uses raw sockets.

<P>
Source code: <A HREF="macaddress.pl">macaddress.pl</A>.<BR>

<P>
When calling macaddress as a CGI script, a setuid-root wrapper is needed
to give the Perl process enough privileges for handling raw sockets.
Here is the wrapper I use. Compile it and do:
<CODE><B>chown root macaddress &amp;&amp; chmod 4711 macaddress</B></CODE>.
<P>
<PRE>
#include &lt;unistd.h&gt;
#include &lt;stdio.h&gt;
#define PROGRAM_PATH "/usr/local/bin/macaddress.pl"

main(int argc, char *argv[]) {
    argv[1] = 0;
    execvp(PROGRAM_PATH, argv);
    fprintf(stderr, "%s: exec failed.\n", argv[0]);
    exit(1);
}
</PRE>

<HR>

</BODY>
</HTML>
