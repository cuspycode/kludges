#!/usr/local/bin/perl -T -w

my $arp_path = "/usr/sbin/arp";

use CGI;
use Getopt::Std;
use Socket;
use FileHandle;
use English;

my $count = 2;
my $sortby = 'IP';
my $iprange = '192.36.125.1-254';
my $timeout = 2;

my %found = ();
my %name = ();
my %mac = ();

sub read_arpcache {
    #
    #  The next line is a shell-safe pipe call (see "man perlsec")
    #
    open(ARP, "-|") or exec $arp_path, "-a" or die "${arp_path} failed";

    #
    #  Parent process can now read output from "arp -a" here.
    #
    while (<ARP>) {
	if (/^(\S+) \(((\d+\.){3}?\d+)\) at (([0-9a-f]+:)+[0-9a-f]+)/) {
	    my $name = $1;
	    my $ip = $2;
	    my $mac = $4;
	    if ($found{$ip}) {
		$name{$ip} = $name;
		$mac{$ip} = $mac;
	    }
	}
    }

    close(ARP);
}

#
#  Convert dotted-quad IP address into 32-bit number
#
sub from_quad {
    my $ip = shift;
    if ($ip =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/) {
	return (($1*256+$2)*256+$3)*256+$4;
    }
}

#
#  Convert 32-bit number to dotted-quad string
#
sub to_quad {
    my $i = shift;
    my @b = ();
    foreach (1..4) {
	unshift @b, ($i & 0xff);
	$i = $i >> 8;
    }
    return join(".", @b);
}

#
#  Calculate packet checksum as described in RFC 1071
#
sub ip_checksum {
    my $packet = shift;
    my $sum = 0;
    foreach (unpack("S*", $packet)) {
	$sum += $_;
    }
    my $len = length($packet);
    if ($len % 2) {
	$sum += unpack("C", substr($packet, $len-1, 1));
    }
    while ($sum >> 16) {
	$sum = ($sum & 0xffff) + ($sum >> 16);
    }
    return 0xffff & ~$sum;
}

#
#  Open a socket and use it to send ICMP ECHO packets to
#  a range of addresses, and then collect the replies.
#
sub doping {
    my $packet;
    my $icmp_fmt = "C2 S3 a*";		# Format of ICMP ECHO packet
    my $ICMP_ECHOREPLY = 0;		# ICMP packet types
    my $ICMP_ECHO = 8;
    my $checksum = 0;
    my $ident = $$ & 0xffff;
    my $seq = 1;
    my $data = "foo";
    $packet = pack $icmp_fmt, $ICMP_ECHO, 0, $checksum, $ident, $seq, $data;
    $checksum = &ip_checksum($packet);
    $packet = pack $icmp_fmt, $ICMP_ECHO, 0, $checksum, $ident, $seq, $data;

    if ($EFFECTIVE_USER_ID ne 0) {
	print STDERR "${PROGRAM_NAME}: ICMP sockets require root privilege\n";
	return undef;
    }

    socket(PING, PF_INET, SOCK_RAW, getprotobyname('icmp'));

    my $address = "127.0.0.1";
    my $max_offset = 0;

    return undef unless $iprange;
    $iprange =~ s/^\s//g;
    if ($iprange =~ s/^((\d+\.){2}\d+)//) {
	my $netnum = $1;
	$address = 0;
	if ($iprange =~ s/^\.(\d+)//) {
	    $address = $1;
	}
	if ($iprange =~ s/-(\d+)//) {
	    $max_offset = $1 - $address;
	}
	$address = "$netnum.$address";
    } else {
	return undef;
    }

    my $ip_start = &from_quad($address);

    @targets = ();

    foreach (0..$max_offset) {
	push @targets, &to_quad($ip_start + $_);
    }

    @targets = map { inet_aton($_); } @targets;

    my @saddr_list = map { pack_sockaddr_in(0, $_); } @targets;
    my @outq = @saddr_list;
    my $repeat = $count;

    my %reachable = ();

    my $rbits = "";
    vec($rbits, PING->fileno(), 1) = 1;
    my $status = 1;
    my $done = 0;
    my $timeleft = $timeout;
    my $finish_time;
    while (!$done && $timeleft > 0) {		# Keep trying if we have time
	if (@outq) {
	    $finish_time = time() + $timeout;
	    send(PING, $packet, 0, shift(@outq));
	    if (!@outq) {
		if ($repeat > 0) {
		    @outq = @saddr_list;
		    $repeat--;
		}
	    }
	}
	my $pkg_wait = 0;
	$every_nth++;
	if ($every_nth >= 10) {
	    $every_nth = 0;
	    $pkg_wait = 0.025;
	}
	$rout = $rbits;
        $nfound = select($rout, undef, undef, $pkg_wait); # Wait for packet
        $timeleft = $finish_time - time();	# Get remaining time
        if (!defined($nfound)) {		# Hmm, a strange error
	    print "Hmm, a strange error\n";
            $status = undef;
            $done = 1;
        } elsif ($nfound) {			# Got a packet from somewhere
            my $recv_msg = "";
            my $from_saddr = recv(PING, $recv_msg, 1500, 0);
	    if (!$from_saddr) { die "recv failed"; }
            my ($from_port, $from_ip) = sockaddr_in($from_saddr);
	    my $len_msg = length($packet);
            my ($from_type, $from_subcode, $from_chk,
		$from_pid, $from_seq, $from_msg) =
		    unpack($icmp_fmt,
			   substr($recv_msg, length($recv_msg) - $len_msg,
				  $len_msg));
            if (($from_type == $ICMP_ECHOREPLY) &&
                ($from_pid == $ident) && # Does the packet check out?
                ($from_seq == $seq))
	    {
		$reachable{$from_ip} = 1;
                $done = 0;
            }
	} else {
	    $done = 0;
	}
    }

    foreach (@targets) {
	if ($reachable{$_}) {
	    $found{inet_ntoa($_)} = 1;
	}
    }

    return $status;
}

sub getmac { return $mac{$_[0]} || ''; }

sub getname { return $name{$_[0]} || ''; }

sub report {
    my $text = "";
    my @keys;

    if ($sortby eq 'MAC') {
	@keys = sort { &getmac($a) cmp &getmac($b) } keys %found;
    } elsif ($sortby eq 'DNS') {
	@keys = sort { &getname($a) cmp &getname($b) } keys %found;
    } else {
	@keys = sort { &from_quad($a) <=> &from_quad($b) } keys %found;
    }

    foreach (@keys) {
	$text .= sprintf "%-15s %-17s %s\n", $_, &getmac($_), &getname($_);
    }
    return $text;
}

if (@ARGV) {
    #
    #  Assume we were called from command line
    #
    my %opts = ();
    getopts("c:", \%opts);
    if ($opts{'c'}) {
	$count = $opts{'c'};
    }
    $iprange = $ARGV[0];
    if (&doping && &read_arpcache) {
	print &report();
    } else {
	print STDERR "Usage: ${PROGRAM_NAME} [-c packetcount] a.b.c.d-e\n";
    }
} else {
    #
    #  Assume we were called via CGI
    #
    my $cgi = new CGI;
    if ($cgi->param) {
	my $c = $cgi->param('c');
	if ($c) {
	    $count = $c;
	}
	my $s = $cgi->param('sort');
	if ($s) {
	    $sortby = $s;
	}
	$iprange = $cgi->param('a');
    }
    my $uri = $cgi->self_url();
    my %c_labels = ( 2 => '2 packets',
		     3 => '3 packets',
		     4 => '4 packets',
		     5 => '5 packets',
		     );
    my $menu = $cgi->popup_menu(-name=>'c',
				-values=>[2,3,4,5],
				-default=>$count,
				-labels=>\%c_labels);
    my $radio = $cgi->radio_group(-name=>'sort',
				  -values=>['IP','MAC','DNS'],
				  -default=>$sortby);
    my $summary = "";
    print $cgi->header;
    select(STDOUT); $| = 1;
    print qq(
<HTML>
<HEAD>
<TITLE>MAC address collector</title>
</HEAD>
<BODY BGCOLOR="#FFFFFF">
<H1>MAC address collector</H1>
Obtain MAC addresses on the local network by sending pings (ICMP_ECHO).
<P>
<TABLE BGCOLOR="#C0C0C0" BORDER=0 CELLSPACING=0 CELLPADDING=5>
<TR>
<TD WIDTH=10%>&nbsp;
<TD>
<FORM METHOD=GET ACTION="${uri}">
IP address(es) to ping:
<INPUT NAME=a SIZE=19 VALUE="${iprange}">
${menu}
<INPUT TYPE=SUBMIT VALUE="Ping!">
<BR>
Sort results by: ${radio}
</FORM>
<TD WIDTH=10%>&nbsp;
</TABLE>
<P>
	    );
    if ($cgi->param) {
	print "<HR>\n";
	print "Have patience, this may take a couple of seconds...<BR>\n";
	if (&doping) {
	    print "Reading ARP cache...<BR>\n";
	    if (&read_arpcache) {
		print "<PRE>\n";
		print &report;
		print "</PRE>\n";
	    }
	}
	$summary = scalar(keys %found) . " hosts found.";
    }

    print qq(
<P>
<HR>
${summary}
</BODY>
</HTML>
	    );

}

