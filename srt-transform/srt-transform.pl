#!/usr/bin/perl

use Getopt::Long;

my $opt_ipfs = undef;
my $opt_oipfs = undef;
my $opt_slope = undef;
my $opt_offset = 0;
my $opt_help = undef;

GetOptions('ifps=f' => \$opt_ifps,
           'ofps=f' => \$opt_ofps,
	   'slope=f' => \$opt_slope,
	   'offset:f' => \$opt_offset,
	   'help' => \$opt_help);

if ($opt_help) {
    print qq(Usage:
        $0 --slope A [--offset B]
        $0 --ifps F --ofps G [--offset B]

        Read an SRT file from STDIN, transform the timestamps, and write to STDOUT.
        The first invocation does the affine transformation t' = At + B, where
        B is zero milliseconds if omitted. The second invocation does the same
        thing, but calculates A from the framerates F and G as follows: A = F/G.
        For example, --ifps 23.976 --ofps 25 adjusts the timestamps to fit a
        25 fps movie when the original framerate was 23.976 fps. This is a common
        framerate for 24 fps movies that were slowed to 23.976 fps during viewing
        on an NTSC display.

        $0 --help

        Print this help message and exit.);
    print "\n";
    exit 0;
}

my $slope = 1;
my $offset = $opt_offset;

if ($opt_slope) {
    if (defined($opt_ifps) || defined($opt_ofps)) {
	die "Can't combine option --slope with --ifps/ofps\n";
    }
    $slope = $opt_slope;
} elsif (defined($opt_ifps) && defined($opt_ofps)) {
    $slope = $opt_ifps/$opt_ofps;
} elsif (defined($opt_ifps) && !defined($opt_ofps)) {
    die "Missing --ofps option\n";
} elsif (defined($opt_ofps) && !defined($opt_ifps)) {
    die "Missing --ifps option\n";
} else {
    die "Neither --slope nor --ifps/ofps options were specified\n";
}

sub parse_time {
    my ($h,$m,$s,$millis) = @_;
    return (($h*60 + $m)*60 + $s)*1000 + $millis;
}

sub transform {
    my ($t) = @_;
    return $slope*$t + $offset;
}

sub format_time {
    my ($t) = @_;
    $t = int($t + 0.5);
    my $millis = $t % 1000;
    $t = ($t - $millis)/1000;
    my $s = $t % 60;
    $t = ($t - $s)/60;
    my $m = $t % 60;
    my $h = ($t - $m)/60;
    return sprintf("%02d:%02d:%02d,%03d", $h, $m, $s, $millis);
}

my $id_seen = 0;

while (defined(my $line = <STDIN>)) {
    if ($line =~ m/^\d+\r?$/) {
	print $line;
	$id_seen = 1;
    } elsif ($id_seen && $line=~ m/^(\d\d):(\d\d):(\d\d),(\d\d\d) --> (\d\d):(\d\d):(\d\d),(\d\d\d)\r?$/) {
	print &format_time(&transform(&parse_time($1,$2,$3,$4)));
	print " --> ";
	print &format_time(&transform(&parse_time($5,$6,$7,$8)));
	print "\r\n";
	$id_seen = 0;
    } else {
	print $line;
	$id_seen = 0;
    }
}

1;
