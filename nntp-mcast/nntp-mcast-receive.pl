#!/usr/bin/perl

use strict;
use FileHandle;
use Digest::MD5;
use Socket;
require "netinet/in.ph"; # You must run "h2ph netinet/*" before using in.ph

my $dest = $ARGV[0];
my $destport = $ARGV[1];
my $ttl = 128;
my $iaddr = gethostbyname($dest);
my $peer = sockaddr_in($destport, $iaddr);

my $protocolversion = undef;
my $partnumber = undef;
my $lastpartflag = undef;
my $md5checksum = undef;
my $messageid = undef;
my $articledatapart = undef;

my $feeding_article = 0;
my $outartmsgid = undef;
my $outartpartno = undef;

my %article = ();
my %lastpartno = ();
my %partscount = ();

my @waitq = ();
my %in_waitq = ();
my $size_waitq = 0;
my $max_waitq = 3;

my @outq = ();
my %in_outq = ();
my $size_outq = 0;
my $max_outq = 3;

sub dispatch_datagram {
    my $enter_outq = 0;
    my $parts = $article{$messageid};
    if (!$parts) {
	$parts = {};
	$article{$messageid} = $parts;
	$partscount{$messageid} = 0;
	print STDOUT "** initializing tables for $messageid\n";
    }
    if (!exists($$parts{$partnumber})) {
	$partscount{$messageid} += 1;
    }
    print STDOUT "** storing part $partnumber for $messageid\n";
    $$parts{$partnumber} = $articledatapart;
    if ($lastpartflag) {
	$lastpartno{$messageid} = $partnumber;
    }
    if (exists($lastpartno{$messageid}) &&
	    $lastpartno{$messageid} == $partscount{$messageid}) {
	print STDOUT "** lastpartno seems to be: ", $lastpartno{$messageid}, "\n";
	if ($in_waitq{$messageid}) {
	    delete $in_waitq{$messageid};
	    $size_waitq--;
	}
	$enter_outq = 1;
    } elsif (!$in_waitq{$messageid} && !$in_outq{$messageid}) {
	push @waitq, $messageid;
	$in_waitq{$messageid} = 1;
	$size_waitq++;
	if ($size_waitq > $max_waitq) {
	    my $oldmsgid = shift @waitq;
	    while (!$in_waitq{$oldmsgid} && @waitq) {
		$oldmsgid = shift @waitq;
	    }
	    if ($in_waitq{$oldmsgid}) {
		print STDOUT "** Expiring from waitq: $oldmsgid\n";
		delete $in_waitq{$oldmsgid};
		$size_waitq--;
		delete $article{$oldmsgid};
		delete $lastpartno{$oldmsgid};
		delete $partscount{$oldmsgid};
	    }
	}
    }
    if ($enter_outq) {
	push @outq, $messageid;
	$in_outq{$messageid} = 1;
	$size_outq++;
	print STDOUT "** hey, we got a message ID! $messageid\n";
	if ($size_outq > $max_outq) {
	    my $oldmsgid = shift @outq;
	    while (!$in_outq{$oldmsgid} && @outq) {
		$oldmsgid = shift @outq;
	    }
	    if ($in_outq{$oldmsgid}) {
		print STDOUT "** Expiring from outq: $oldmsgid\n";
		delete $in_outq{$oldmsgid};
		$size_outq--;
		delete $article{$oldmsgid};
		delete $lastpartno{$oldmsgid};
		delete $partscount{$oldmsgid};
	    }
	}
    }
}

sub read_nntp_response {
#####    my $response = <NNTP>;
    # Just ignore it...
}

sub feed_nntp {
    if (!defined($outartmsgid)) {
	if (@outq) {
	    $outartmsgid = shift @outq;
	    while (!$in_outq{$outartmsgid} && @outq) {
		$outartmsgid = shift @outq;
	    }
	    if ($in_outq{$outartmsgid}) {
		print STDOUT "** Found something to feed: $outartmsgid\n";
		delete $in_outq{$outartmsgid};
		$size_outq--;
		&read_nntp_response();
		$outartpartno = 1;
		print NNTP "takethis $outartmsgid\015\012";
	    }
	}
    }
    if (defined($outartmsgid)) {
	my $parts = $article{$outartmsgid};
	my $data = $$parts{$outartpartno};
	print STDOUT "** outartpartno for $outartmsgid is $outartpartno\n";
	print NNTP $data;
	$outartpartno++;
	if ($outartpartno > $lastpartno{$outartmsgid}) {
	    delete $article{$outartmsgid};
	    delete $lastpartno{$outartmsgid};
	    delete $partscount{$outartmsgid};
	    $outartmsgid = undef;
	}
    }
}

sub parse_packet {
    my $stuff = shift;
    if ($stuff =~ /^(\d)\012(\d{7})([+*])\012(-|[0-9a-f]{32})\012([^\012]+)\012(.*)$/s) {
	$protocolversion = $1;
	$partnumber = $2 + 0;
	$lastpartflag = ($3 eq '*'? 1 : 0);
	$md5checksum = $4;
	$messageid = $5;
	$articledatapart = $6;
	if ($messageid =~ /^<[^>]+>$/) {
	    return 1;
	}
    }
    print STDOUT "** parse_packet failed\n";
    return 0;
}

sub membership {
    my $group = shift;
    return pack("a4a4", inet_aton($group), INADDR_ANY);
}

socket(SOCK, PF_INET, SOCK_DGRAM, getprotobyname('ip')) or die("Socket: $!");
setsockopt(SOCK, &IPPROTO_IP, &SO_REUSEADDR, pack("l",0)) or die("Reuse");
setsockopt(SOCK, SOL_SOCKET, SO_RCVBUF, pack("L",233000));	# sysctl this!
bind(SOCK, sockaddr_in($destport, INADDR_ANY)) or die("Bind: $!");
setsockopt(SOCK, &IPPROTO_IP, &IP_MULTICAST_LOOP, pack("l",0)) or die("Loop");
setsockopt(SOCK, &IPPROTO_IP, &IP_MULTICAST_TTL, pack("l",$ttl)) or die("TTL");
setsockopt(SOCK, &IPPROTO_IP, &IP_ADD_MEMBERSHIP, &membership($dest)) or die("Add: $!");

open NNTP, ">nntp-mcast-receive.nntp" or die "Couldn't open output file";
select NNTP; $|=1; select STDOUT;

my $rbits = "";
my $wbits = "";
vec($rbits, SOCK->fileno(), 1) = 1;
vec($wbits, NNTP->fileno, 1) = 1;

while (1) {
    my $rout = $rbits;
    my $wout = $wbits;
    if (select($rout, $wout, undef, 10)) {
	if (vec($rout, SOCK->fileno(), 1)) {
	    my $packet = "";
	    my $from_saddr = recv(SOCK, $packet, 2000, 0) || die "recv: $!";
	    my ($from_port, $from_ip) = sockaddr_in($from_saddr);
	    $from_ip = inet_ntoa($from_ip);
#	    print STDERR "Packet from ${from_ip} port ${from_port}\n";
	    if (&parse_packet($packet)) {
		&dispatch_datagram();
	    }
	} elsif (vec($wout, NNTP->fileno(), 1)) {
	    &feed_nntp();
	}
    }
}

close NNTP;

1;
