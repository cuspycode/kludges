#!/usr/local/bin/perl

use Getopt::Std;
use Socket;
use FileHandle;
use Time::Local;
require "netinet/in.ph"; # You must run "h2ph netinet/*" before using in.ph

my $dest = $ARGV[0];
my $destport = $ARGV[1];

sub membership {
    my $group = shift;
    return pack("a4a4", inet_aton($group), INADDR_ANY);
}

socket(SOCK, PF_INET, SOCK_DGRAM, getprotobyname('ip')) or die("Socket");
print STDERR "got a socket\n";

bind(SOCK, sockaddr_in($destport, INADDR_ANY));
print STDERR "bind to port succeeded\n";

setsockopt(SOCK, &IPPROTO_IP, &SO_REUSEADDR, pack("l",0)) or die("Loop");
print STDERR "setsockopt SO_REUSEADDR=0\n";

setsockopt(SOCK, &IPPROTO_IP, &IP_MULTICAST_LOOP, pack("l",0)) or die("Loop");
print STDERR "setsockopt IP_MULTICAST_LOOP=0\n";

setsockopt(SOCK, &IPPROTO_IP, &IP_MULTICAST_TTL, pack("l",128)) or die("TTL");
print STDERR "setsockopt IP_MULTICAST_TTL=128\n";

setsockopt(SOCK, &IPPROTO_IP, &IP_ADD_MEMBERSHIP, &membership($dest)) or die("Add: $!");
print STDERR "setsockopt IP_ADD_MEMBERSHIP=($dest,0)\n";

my $iaddr = gethostbyname($dest);
my $peer = sockaddr_in($destport, $iaddr);

my $rbits = "";
vec($rbits, SOCK->fileno(), 1) = 1;

my $file = 1;
chdir "storedpackets" or die "Couldn't chdir to storedpackets directory";

while (1) {
    my $rout = $rbits;
    if (select($rout, undef, undef, 10)) {
	if (vec($rout, SOCK->fileno(), 1)) {
	    my $packet = "";
	    my $from_saddr = recv(SOCK, $packet, 2000, 0) || die "recv: $!";
	    my ($from_port, $from_ip) = sockaddr_in($from_saddr);
####	    chomp $packet;
	    $from_ip = inet_ntoa($from_ip);
	    print STDERR "Packet from ${from_ip} port ${from_port}, length ",
			 length($packet), " => $file.\n";
####	    print STDOUT $packet, "\n\n";
	    my $n1 = int ($file / 100);
	    my $n2 = sprintf("%02d", $file - 100*$n1);
	    open FILE, ">$n1/$n2" or die "Couldn't open file $n1/$n2";
	    print FILE $packet;
	    close FILE;
	    $file++;
	}
    }
}

