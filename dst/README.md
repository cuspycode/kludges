<HTML>
<HEAD>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset="ISO-8859-1">
<!-- <TITLE>UTC in crontabs</TITLE> -->
<LINK REL=StyleSheet HREF="../style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY>
<H1>UTC in crontabs</H1>
<P>
Among all the stupidities that have been made into law by politicians, Daylight Saving Time (DST) is one of the more persistent ones in our present-day culture. The basic idea seems to be that the local time zone needs to be adjusted so that evenings have as much daylight as possible during summer, when the days are longer anyway, while the opposite adjustment must be made in the winter, when that extra hour of late daylight could actually have been useful! Does that sound like a smart idea?

<P>
To top off the stupidity, the method used for these time adjustments is unlike all other regular calendar adjustments (like <A HREF="http://scienceworld.wolfram.com/astronomy/LeapYear.html">leap days</A>,
or <A HREF="http://www.leapsecond.com/java/gpsclock.htm">leap seconds</A>).
For the 23-hour day in March the hours are not counted as 0, 1, 2, 3, ..., 22, but as 0, 1, 3, 4, ..., 23. And it's even worse for the 25-hour day in October where the hours are not counted as 0, 1, 2, 3, ..., 24, but as 0, 1, 2, 2, 3, ..., 23.

<P>
To avoid the problems associated with this silly nonsense, one can of course use a sane time standard like
<A HREF="http://www.bipm.fr/en/scientific/tai/tai.html">TAI</A>
or
<A HREF="http://en.wikipedia.org/wiki/Coordinated_Universal_Time">UTC</A>,
or some reasonable approximation of such a standard. For example, Unix and Linux computers follow the POSIX standard that uses a time base that approximates UTC. The only difference from UTC occurs in the vicinity of leap seconds. This means that the system's timestamps represent physical time coordinates fairly well, since the variation in day length due to leap seconds is only 86401/86400 = 1e-5 = 0.001%. This should be compared with a DST calendar, where the variation in day length is more than 4% (since a 25-hour day is 4.167% longer than a 24-hour day).

<P>
There is however a big problem with the program "cron". POSIX mandates that the time specifications used in the crontab files should be understood as times in the local time zone. This sounds reasonable, but it means that changing the time zone may affect the interval between executions of certain jobs. A simple fix would be to extend the crontab format to allow UTC times <I>as well as</I> local times. Jobs scheduled at UTC times would not be affected by a change of time zone, regardless of whether the change is due to a DST transition or to a physical movement of the computer that is accompanied by switching to a different time zone.

<P>
I implemented such a fix in 1999 through a
<A HREF="http://urquell.pilsnet.sunet.se:8000/cron-utc-patch.txt">patch</A>
to cron that allows a crontab file to mix local times and UTC times. By setting the environment variable CRONTAB_UTC=1 in the crontab file, subsequent entries are interpreted as UTC times. And by setting CRONTAB_UTC=0, the local-time interpretation is restored again for remaining entries.

This simple patch was easy to install in most versions of Vixie cron that were in use in 1999. But in recent releases of FreeBSD and Debian Linux (I have only checked those and Gentoo so far) changes have been made to cron that are incompatible with my original patch. These changes are different in FreeBSD and Debian, so therefore there are now three separate patches for my CRONTAB_UTC hack:

<UL>
<LI><B>FreeBSD</B><BR>
<A HREF="http://urquell.pilsnet.sunet.se:8000/freebsd4-cron-utc-patch.txt">http://urquell.pilsnet.sunet.se:8000/freebsd4-cron-utc-patch.txt</A><BR>
This one has so far been tested in FreeBSD 4.8-RELEASE and 4.9-RELEASE. To install, download the patch file and do:

<PRE>
cd /usr/src/usr.sbin/cron/
patch -p0 < ~/freebsd4-cron-utc-patch.txt
make clean
make
</PRE>

Then kill your running cron, copy the newly compiled ./cron/cron to
wherever you want, and start it.

<P>
<LI><B>Debian Linux</B><BR>
<A HREF="http://urquell.pilsnet.sunet.se:8000/debian3-cron-utc-patch.txt">http://urquell.pilsnet.sunet.se:8000/debian3-cron-utc-patch.txt</A><BR>
This has been tested in Debian 3.0 ("woody") against the cron_3.0pl1-81 source ("unstable"). To install, download the patch file and do:

<PRE>
apt-get source cron
cd cron-3.0pl1
patch -b < ~/debian3-cron-utc-patch.txt
make clean
make
</PRE>

Then kill your running cron, copy your new cron to wherever you want,
and start it.

<P>
<LI><B>Gentoo Linux</B><BR>
<A HREF="http://urquell.pilsnet.sunet.se:8000/gentoo2004.1-cron-utc-patch.txt">http://urquell.pilsnet.sunet.se:8000/gentoo2004.1-cron-utc-patch.txt</A><BR>
This has been tested in Gentoo 2004.1 against the unpacked and patched vixie-3.0.1-r4 sources. To install, download the patch file and do:

<PRE>
cd /usr/portage/sys-apps/vixie-cron/
ebuild vixie-cron-3.0.1-r4.ebuild unpack
cd /var/tmp/portage/vixie-cron-3.0.1-r4/work/vixie-cron-3.0.1/
patch -b < ~/gentoo2004.1-cron-utc-patch.txt
make clean
make
</PRE>

Then kill your running cron, copy your new cron to wherever you want,
and start it.
</UL>

Now you can have a crontab like

<PRE>
CRONTAB_UTC=1
42 05,11,17,23 * * * do-six-hour-intervals
</PRE>

...and the job "do-six-hour-intervals" will keep repeating at six hour
intervals, not five or seven hour intervals on some days, for as long as
the computer is up and running and is reasonably synchronized with
a UTC time base.

<P>
Similar patches should work on other operating systems that use cron versions
based on Vixie cron, but you may have to create your own patch file or put in
the changes by hand.

<P>
Final note: It's interesting to see how the FreeBSD and Debian people have
tackled the DST problem. The FreeBSD version of cron tries to detect time
zone changes and then reschedules jobs so they do what's "intuitively expected"
according to the manpage. This of course makes the code less transparent
and less maintainable, and if you think about it you can't fix an inherently
non-intuitive mistake like DST by forcing various ad-hoc rules upon the
victims of the mistake... The Debian version on the other hand tries to
detect time shifts in the UTC clock, and reschedules jobs that are skipped
or duplicated because of this. This is somewhat more useful, since it is a
recovery mechanism for situations where the UTC clock suddenly gets corrected
after having been out of sync. But the comments in the source code seem to
indicate that the author believes that this has something to do with
time zone shifts and DST transitions, which of course it does not.

<P>
But never mind all that. Just install my patch and relax :)

<P>
Happy hacking,<BR>
Bj&ouml;rn Danielsson<BR>
<HR>
Page updated: 2004-10-31
</BODY>
</HTML>
