#!/usr/bin/perl

use strict;
use FileHandle;
use Digest::MD5;
use Socket;

my $maxarts = $ARGV[0];
my $stop = 0;

my $hostname = `hostname`;
chomp $hostname;

STDOUT->autoflush(1);

chdir "storedarticles" or die "Couldn't chdir to storedarticles";
my $file = 1;

my $md5 = undef;
my $md5checksum = undef;
my $artbuf = undef;
my $article = undef;
my $reading_article = undef;
my $transmit_done = 1;

my $nart = 0;
my $bytes = 0;
my $t_read = time;

sub start_reading_article {
    $t_read = time;
    $reading_article = 1;
    $artbuf = "";
    $md5 = new Digest::MD5;
}

sub transmit_article {
    $md5checksum = $md5->hexdigest;
    $bytes += length($article);
    $nart++;
    if ($nart % 100 == 0) {
	print STDOUT "[$nart articles with a total of $bytes bytes]\n";
    }
    if ($maxarts) {
	open FILE, ">$file" or die "Couldn't open file $file";
	print FILE $article;
	close FILE;
	open MD5SUMS, ">>md5sums" or die "Couldn't open file md5sums";
	print MD5SUMS "$file: $md5checksum\n";
	close MD5SUMS;
	$file++;
	$stop = 1 if $file > $maxarts;
    }
    $transmit_done = 1;
}

my $tcp = getprotobyname('tcp');
my $servport = $ENV{NNTP_PORT} || 1119;

socket(PORT, PF_INET, SOCK_STREAM, $tcp);
setsockopt(PORT, SOL_SOCKET, SO_REUSEADDR, pack("l",1));
bind(PORT, sockaddr_in($servport, INADDR_ANY));
listen(PORT, SOMAXCONN);

while (!$stop && accept(NNTP, PORT)) {
    setsockopt(NNTP, SOL_SOCKET, SO_RCVBUF, pack("L",65536));	# sysctl this!
    NNTP->autoflush(1);
    my $readbuf = "";
    my $messageid = undef;
    print NNTP "200 $hostname News slurper script 1.0 ready\015\012";
    $nart = 0;
    $bytes = 0;
    my $t = time;
    $reading_article = 0;
    my $rbits = "";
    my $wbits = "";
    vec($rbits, NNTP->fileno, 1) = 1;
    my $eof = 0;
    while (!$stop) {
	my $rout = $rbits;
	my $wout = $wbits;
	select($rout, $wout, undef, 1);
	if (vec($rout, NNTP->fileno, 1) && $transmit_done && !$eof) {
	    my $data = "";
	    my $retval = sysread(NNTP, $data, 65536);
	    my $l = length($data);
	    $eof = 1 unless $retval;
	    $readbuf .= $data;
	}
	my $more = 1;
	while ($more) {
	    if ($reading_article) {
		if (time - $t_read > 60) {
		    print STDOUT "** Article read timeout\n";
		    $stop = 1;
		    $more = 0;
		}
		my $artlen = length($artbuf);
		$artbuf .= $readbuf;
		my $artend = index($artbuf, "\012.\015\012", $artlen-3);
#		    print STDOUT "** artend index: $artend\n";
		if ($artend > -1) {
		    $article = substr($artbuf, 0, $artend+4);
		    $md5->add(substr($readbuf, 0, $artend+4-$artlen));
		    $readbuf = substr($readbuf, $artend+4-$artlen);
		    $reading_article = 0;
		    &transmit_article;
		    print NNTP "239 $messageid\015\012";
		} else {
		    last if $eof;
		    $md5->add($readbuf);
		    $readbuf = "";
		    $more = 0;
		}
	    } else {
		my $endline = index($readbuf, "\012");
		if ($endline > -1) {
		    my $line = substr($readbuf, 0, $endline+1);
		    $readbuf = substr($readbuf, $endline+1);
#			print STDOUT "** Found NNTP command: $line";
		    if ($line =~ m/^\s*CHECK\s+(<[^>]+>)/i) {
			print NNTP "238 $1\015\012";
		    } elsif ($line =~ m/^\s*TAKETHIS\s+(<[^>]+>)/i) {
			$messageid = $1;
#			    print NNTP "239 $1\015\012";
			&start_reading_article;
		    } elsif ($line =~ m/^\s*IHAVE\s+(<[^>]+>)/i) {
			$messageid = $1;
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

1;
