<HTML>
<HEAD>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset="ISO-8859-1">
<!-- <TITLE>JuestBook</TITLE> -->
<LINK REL=StyleSheet HREF="../style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY>
<H1>JuestBook</H1>
<P>
A very simple Java applet/servlet combination that lets people paint small
images in an applet window, and then upload them (as GIFs) to the server.

<P>
The applet uses
<A HREF="http://www.acme.com/">Jef Poskanzer's code</A>
for encoding images (GIFs).

<P>
The server uses some JSP code, running under Tomcat, which is invoked
transparently from Apache via mod_jk. If you want to customize it for
your own site you probably need to adjust the URLs in the <B>.jsp</B>
and the <B>.shtml</B> files. The applet <B>.jar</B> should work as it
is without patching or recompilation. But don't forget to set write permission
on the upload directory for the userid that runs Tomcat (you do run Tomcat
as "www", "apache", or "nobody" but never as "root", right?)

<P>
<A HREF="http://fulhack.dax.nu/gastbok.shtml">Example page</A>.
You'll need a browser with Java 1.1 or later to play with the applet.

<P>
<A HREF="http://fulhack.dax.nu/juestbook.src/">Source code</A> for the applet
and the JSP services.

<HR>

</BODY>
</HTML>
