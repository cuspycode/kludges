<HTML>
<HEAD>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset="ISO-8859-1">
<!-- <TITLE>NNTP via Multicast in Perl</TITLE> -->
<LINK REL=StyleSheet HREF="../style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY>
<H1>NNTP via Multicast in Perl</H1>
<P>
Back in 2002 there were several versions of software available that could
distribute Usenet feeds over multicast. However, none that I was aware of
could handle articles larger than 65536 bytes, the maximum size of an IP
packet. So I hacked together about 400 lines of Perl code that implement
a simple NNTP client and server together with the necessary fragmentation
and defragmentation of arbitrary-sized articles. The scripts also handle
their own data checksums (MD5 digests) and multicast transport.

<P>
Deployment: the sending script is fed by a normal NNTP/TCP feed,
for example on the loopback interface on your main feeder machine.
The receiving script runs on a reader machine and feeds the
re-assembled articles to port 119 on localhost. Multiple simultaneous
streams are possible by putting them on different ports.

<P>
The code is highly experimental, especially the receiver. It still uses
blocking I/O for the localhost socket, and it doesn't handle closing of
this socket very well. Also, since the data is broadcast there is no
mechanism for backlogs/requeuing. Therefore a delayed backup feed using
the normal NNTP-over-TCP protocol is recommended on each receiver.

<P>
<DL>
<DT>Source code:
<DD><A HREF="nntp-mcast-send.pl">nntp-mcast-send.pl</A>.<BR>
<A HREF="nntp-mcast-receive.pl">nntp-mcast-receive.pl</A>.<BR>
</DL>

<HR>

</BODY>
</HTML>
