<HTML>
<HEAD>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset="ISO-8859-1">
<!-- <TITLE>Trashy File Transfer Protocol</TITLE> -->
<LINK REL=StyleSheet HREF="../style.css" TYPE="text/css" MEDIA=screen>
</HEAD>
<BODY>
<H1>Trashy File Transfer Protocol</H1>
<P>
Many years ago I used the <I>Trivial File Transfer Protocol</I> aka TFTP (RFC783)
to push files from servers to a host that collected statistics. Other methods such
as NFS or ordinary FTP were rejected as too unsafe or because they had unnecessarily
large footprint. But since TFTP doesn't use TCP transport there were recurring
problems with packet loss. So after a hardware upgrade I created this hack as a
replacement for TFTP in my scripts. This was painless compared to reconfiguring
the infrastructure to use a completely different method for the file transfers...

<P>
The hack consists of two scripts:
<P>
<HR>
<PRE>
#!/usr/bin/perl

&#35;#######################################################################
&#35;								       #
&#35; TFTP-put over TCP.						       #
&#35;								       #
&#35; This is the daemon part of a TFTP protocol replacement for the       #
&#35; case where only "put" commands are used. Run it from inetd as some   #
&#35; non-root user and prepare /etc/hosts.allow to restrict access.       #
&#35; A -s &lt;directory&gt; argument is mandatory.			       #
&#35;								       #
&#35;#######################################################################

use Socket;
use Getopt::Std;

my %opt = ();
getopts('s:', \%opt);

my $dir = $opt{s};
die "No directory specified" unless defined($dir);

my $line = &lt;STDIN&gt;;
if (length($line) &lt; 10000 &amp;&amp; $line =~ m/^Kaka (\S+)/) {
    $line = $1;
    if (grep /^(|\.|\.\.)$/, split("/", $line)) {
	die "Illegal destination path: $line";
    }
    $dir =~ s{/$}{};
    my $path = "$dir/$line";
    open FILE, ">$path" or die "Couldn't open $path for writing\n$!";
    my $buffer = "";
    my $size = 32768;
    while (1) {
	my $n = read(STDIN, $buffer, $size);
	last if !defined($n) || $n == 0;
	syswrite(FILE, $buffer, $n);
    }
    close FILE;
}

1;
</PRE>

<HR>
<PRE>
#!/usr/bin/perl

########################################################################
#                                                                      #
# TFTP-put over TCP.                                                   #
#                                                                      #
# This is the client part of a TFTP protocol replacement for the       #
# case where only "put" commands are used. The program exits after     #
# one single put command has been processed, which must be in exactly  #
# the format specified by the regexp in the code. The port to connect  #
# to may be specified with the command-line argument -p &lt;port&gt;.        #
#                                                                      #
########################################################################

use Socket;
use Getopt::Std;

my %opt = ();
getopts('p:', \%opt);

my $port = $opt{p} || "tftp";
my $host = $ARGV[0] || die "No remote host specified";

my $tcp_proto = getprotobyname("tcp");
$port = getservbyname($port, "tcp") unless $port =~ m/^\d+$/;

my $cmd = &lt;STDIN&gt;;

if ($cmd =~ m/^put (\S+) (\S+)/) {
    my $file = $1;
    my $dest = $2;
    socket(CSOCK, PF_INET, SOCK_STREAM, $tcp_proto);
    if (connect(CSOCK, sockaddr_in($port, inet_aton($host)))) {
	open FILE, "&lt;$file" or die "Couldn't open file $file\n$!";
	syswrite(CSOCK, "Kaka $dest\n");
	my $buffer = "";
	my $size = 32768;
	while (1) {
	    my $n = sysread(FILE, $buffer, $size);
	    last if !defined($n) || $n == 0;
	    syswrite(CSOCK, $buffer, $n);
	}
	close(FILE);
	close(CSOCK);
    } else {
	die "No answer from $host:$port";
    }
} else {
    die "Unrecognized command '$cmd'";
}

1;
</PRE>

<HR>

</BODY>
</HTML>
