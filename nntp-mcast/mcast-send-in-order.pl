#!/usr/local/bin/perl

use Getopt::Std;
use Socket;
use FileHandle;
use Time::Local;
require "netinet/in.ph"; # You must run "h2ph netinet/*" before using in.ph

my $dest = shift @ARGV;
my $destport = shift @ARGV;
my $ttl = 4;

sub usleep { select(undef, undef, undef, $_[0]/1000000.0); }

socket(SOCK, PF_INET, SOCK_DGRAM, getprotobyname('ip')) or die("Socket");
print STDERR "got a socket\n";

# bind(SOCK, sockaddr_in($destport, INADDR_ANY));
# print STDERR "bind to port succeeded\n";

setsockopt(SOCK, &IPPROTO_IP, &SO_REUSEADDR, pack("l",0)) or die("Loop");
print STDERR "setsockopt SO_REUSEADDR=0\n";

setsockopt(SOCK, &IPPROTO_IP, &IP_MULTICAST_TTL, pack("l",$ttl)) or die("TTL");
print STDERR "setsockopt IP_MULTICAST_TTL=$ttl\n";

my $iaddr = gethostbyname($dest);
my $peer = sockaddr_in($destport, $iaddr);

my $rbits = "";
vec($rbits, SOCK->fileno(), 1) = 1;

chdir "storedpackets" or die "Couldn't chdir to storedpackets directory";

&usleep(100000);
send(SOCK, "foobar", 0, $peer) || die "send: $!";
&usleep(100000);
&usleep(2000000);

foreach my $item (@ARGV) {
    my $from = 0;
    my $to = -1;
    if ($item =~ m/^\d+$/) {
	$from = $item;
	$to = $item;
    } elsif ($item =~ m/^(\d+)-(\d+)$/) {
	$from = $1;
	$to = $2;
    }
    foreach my $file ($from..$to) {

	my $n1 = int ($file / 100);
	my $n2 = sprintf("%02d", $file - 100*$n1);
	open FILE, "<$n1/$n2" or die "Couldn't open file $n1/$n2";
	undef $/;
	my $data = <FILE>;
	close FILE;
	print STDOUT "Sending packet $file (", length($data), " bytes)\n";
	send(SOCK, $data, 0, $peer) || die "send: $!";
	&usleep(1000);
    }
}

1;
