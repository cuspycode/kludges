#!/usr/local/bin/perl

use Getopt::Std;
use Socket;
use FileHandle;
use Time::Local;
require "netinet/in.ph"; # You must run "h2ph netinet/*" before using in.ph

my $dest = $ARGV[0];
my $destport = $ARGV[1];
my $ttl = 4;

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

send(SOCK, "Allan tar kakan.\n", 0, $peer) || die "send: $!";
