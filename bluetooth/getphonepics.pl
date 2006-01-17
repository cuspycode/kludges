#!/usr/bin/perl
# $Id$

use XML::Parser;
use Time::HiRes qw(time);

local ($phoneid,$phonepath,$obexftp,$download);
$phoneid="00:00:00:00:00:00";
$phonepath = "Foton";
$obexftp = "obexftp";
$download = "$ENV{HOME}/phonepics";
do "$ENV{HOME}/.getphonepicsrc";	# Load bluetooth address into $phoneid,
					# plus other optional configurations.
my @filenames = ();

open OBEX, "$obexftp -b $phoneid -B 10 --list Foton |"
    or die "$obexftp failed: $!";

my $p = new XML::Parser(Style => 'Tree');
my $tree = $p->parse(*OBEX, ProtocolEncoding => 'UTF-8');
close(OBEX);

my ($tag,$content) = @$tree;

die "Bad XML" unless $tag eq 'folder-listing';
my ($attr,@rest) = @$content;
while (@rest) {
    ($tag,$content,@rest) = @rest;
    if ($tag eq 'file') {
	$attr = $$content[0];
	push @filenames, $$attr{name};
    }
}

if (@filenames) {
    my @t = localtime;
    my $date = sprintf "%04d-%02d-%02d", 1900+$t[5], $t[4]+1, $t[3];
    my $dir = undef;
    foreach my $suffix ("",map ".$_",1..9) {
	$dir = "$download/$date$suffix";
	last unless -e $dir;
    }
    die "Too many directories for $date" unless $dir;

    mkdir $dir or die "Couldn't create $dir: $!";
    chdir $dir or die "Couldn't chdir to $dir: $!";

    my $start_time = time;

    my $cmd = "$obexftp -b $phoneid -B 10 --getdelete ";
    $cmd .= join(" ", map "$phonepath/$_", @filenames);

    system($cmd);

    printf "%d files moved to %s in %.3f seconds.\n",
	scalar(@filenames), $dir, time-$start_time;
} else {
    print "No files to download.\n";
}

1;

