#!/usr/bin/perl

########################################################################
#								       #
# TFTP-put over TCP.						       #
#								       #
# This is the daemon part of a TFTP protocol replacement for the       #
# case where only "put" commands are used. Run it from inetd as some   #
# non-root user and prepare /etc/hosts.allow to restrict access.       #
# A -s <directory> argument is mandatory.			       #
#								       #
########################################################################

use Socket;
use Getopt::Std;

my %opt = ();
getopts('s:', \%opt);

my $dir = $opt{s};
die "No directory specified" unless defined($dir);

my $line = <STDIN>;
if (length($line) < 10000 && $line =~ m/^Kaka (\S+)/) {
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
