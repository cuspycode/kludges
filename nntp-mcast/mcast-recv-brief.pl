#!/usr/bin/perl

use Socket;
require "netinet/in.ph"; # You must run "h2ph netinet/*" before using in.ph

$dest = "239.253.0.42";
$destport = 4711;
$ttl = 128;

sub membership {
    my $group = shift;
    return pack("a4a4", inet_aton($group), INADDR_ANY);
}

socket(SOCK, PF_INET, SOCK_DGRAM, getprotobyname('ip'));
bind(SOCK, sockaddr_in($destport, INADDR_ANY));
setsockopt(SOCK, &IPPROTO_IP, &IP_MULTICAST_LOOP, pack("l",0));
setsockopt(SOCK, &IPPROTO_IP, &IP_MULTICAST_TTL, pack("l",$ttl));
setsockopt(SOCK, &IPPROTO_IP, &IP_ADD_MEMBERSHIP, &membership($dest));

$packet = "";
$from_saddr = recv(SOCK, $packet, 65536, 0) || die "recv: $!";
($from_port,$from_ip) = sockaddr_in($from_saddr);
$from_ip = inet_ntoa($from_ip);
print STDERR "Packet from ${from_ip} port ${from_port}:\n";
print STDOUT $packet, "\n\n";
