#!/usr/bin/perl

use strict;
use FileHandle;
use Digest::MD5;
use Socket;
require "netinet/in.ph"; # You must run "h2ph netinet/*" before using in.ph

my $dest = $ARGV[0];
my $destport = $ARGV[1];
my $ttl = 32;
my $iaddr = gethostbyname($dest);
my $peer = sockaddr_in($destport, $iaddr);

my $hostname = `hostname`;
chomp $hostname;

STDOUT->autoflush(1);

my $tcp = getprotobyname('tcp');
my $servport = $ENV{NNTP_PORT} || 1119;

my $protocolversion = '0';
my $partnumber = undef;
my $lastpartflag = undef;
my $md5checksum = undef;
my $messageid = undef;
my $new_messageid = undef;
my $maxdatagramsize = 1472;

my $partbegin = 0;

my $md5 = undef;
my $artbuf = undef;
my $article = undef;
my $reading_article = undef;
my $transmit_done = 1;

sub start_reading_article {
    $reading_article = 1;
    $artbuf = "";
    $md5 = new Digest::MD5;
}

sub transmit_article {
    $md5checksum = $md5->hexdigest;
    $partbegin = 0;
    $partnumber = 1;
    $transmit_done = 0;
    &transmit_article_part;
}

sub transmit_article_part {
    my $partlength = undef;
    my $x1 = "";
    my $x2 = "";
    $x1 .= "$protocolversion\012";
    $x1 .= sprintf "%07d", $partnumber;
    $x2 .= "$md5checksum\012";
    $x2 .= "$messageid\012";
    my $headerlength = length($x1) + 2 + length($x2);
    my $maxpartlength = $maxdatagramsize - $headerlength;
    if (length($article)-$partbegin > $maxpartlength) {
	$x2 = "-\012$messageid\012";
	$partlength = $maxpartlength + 31;
	$partlength = length($article)-$partbegin if length($article)-$partbegin < $partlength;
	$lastpartflag = "+";
    } else {
	$partlength = length($article)-$partbegin;
	$lastpartflag = "*";
	$transmit_done = 1;
    }

    send(SOCK,
	 $x1.$lastpartflag."\012".$x2.substr($article, $partbegin, $partlength),
	 0,
	 $peer);

    $partbegin += $partlength;
    $partnumber++;
}

socket(PORT, PF_INET, SOCK_STREAM, $tcp);
setsockopt(PORT, SOL_SOCKET, SO_REUSEADDR, pack("l",1));
bind(PORT, sockaddr_in($servport, INADDR_ANY));
listen(PORT, SOMAXCONN);

socket(SOCK, PF_INET, SOCK_DGRAM, getprotobyname('ip')) or die("Socket: $!");
setsockopt(SOCK, &IPPROTO_IP, &IP_MULTICAST_TTL, pack("l",$ttl)) or die("TTL");

my $stop = 0;

while (!$stop && accept(NNTP, PORT)) {
    setsockopt(NNTP, SOL_SOCKET, SO_RCVBUF, pack("L",65536));	# sysctl this!
    NNTP->autoflush(1);
    my $readbuf = "";
    $new_messageid = undef;
    print NNTP "200 $hostname News slurper script 1.0 ready\015\012";
    my $t = time;
    $reading_article = 0;
    my $rbits = "";
    my $wbits = "";
    vec($rbits, NNTP->fileno, 1) = 1;
    vec($wbits, SOCK->fileno, 1) = 1;
    my $eof = 0;
    while (!$stop) {
	my $rout = $rbits;
	my $wout = $wbits;
	select($rout, $wout, undef, 1);
	if (vec($wout, SOCK->fileno, 1)) {
	    if (!$transmit_done) {
		&transmit_article_part;
	    }
	}
	if (vec($rout, NNTP->fileno, 1) && !$eof) {
	    my $data = "";
	    my $retval = sysread(NNTP, $data, 65536);
	    my $l = length($data);
	    $eof = 1 unless $retval;
	    $readbuf .= $data;
	}
	my $more = 1;
	while ($more) {
	    if ($reading_article) {
		if (!$transmit_done) {
		    $more = 0;
		} else {
		    my $artlen = length($artbuf);
		    $artbuf .= $readbuf;
		    my $artend = index($artbuf, "\012.\015\012", $artlen-3);
		    if ($artend > -1) {
			$article = substr($artbuf, 0, $artend+4);
			$md5->add(substr($readbuf, 0, $artend+4-$artlen));
			$readbuf = substr($readbuf, $artend+4-$artlen);
			$reading_article = 0;
			$messageid = $new_messageid;
			&transmit_article;
			print NNTP "239 $messageid\015\012";
		    } else {
			last if $eof;
			$md5->add($readbuf);
			$readbuf = "";
			$more = 0;
		    }
		}
	    } else {
		my $endline = index($readbuf, "\012");
		if ($endline > -1) {
		    my $line = substr($readbuf, 0, $endline+1);
		    $readbuf = substr($readbuf, $endline+1);
#		    print STDOUT "** Found NNTP command: $line";
		    if ($line =~ m/^\s*CHECK\s+(<[^>]+>)/i) {
			print NNTP "238 $1\015\012";
		    } elsif ($line =~ m/^\s*TAKETHIS\s+(<[^>]+>)/i) {
			$new_messageid = $1;
			print NNTP "239 $1\015\012";
			&start_reading_article;
		    } elsif ($line =~ m/^\s*IHAVE\s+(<[^>]+>)/i) {
			$new_messageid = $1;
			print NNTP "335 $1\015\012";
			&start_reading_article;
		    } elsif ($line =~ m/^\s*MODE STREAM\s*$/i) {
			print NNTP "203 StreamOK.\015\012";
		    } elsif ($line =~ m/\s*QUIT\s*/i) {
			print NNTP "205 Bye.\015\012";
			last;
		    } else {
			print NNTP "500 Syntax error or bad command\015\012";
		    }
		} else {
		    $more = 0;
		}
	    }
	}
	last if $eof && ($readbuf eq "");
    }
    print STDOUT "** Session time was ", time-$t, " seconds **\n";
    close NNTP;
}

close(PORT);
close SOCK;

1;
