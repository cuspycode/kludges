#!/usr/bin/perl

my $dir = shift @ARGV;
my $start = shift @ARGV;
my $end = shift @ARGV;

chdir $dir or die "Couldn't chdir to $dir";

foreach my $f ($start..$end) {
    open FILE, "<$f" or die "Couldn't open file $f";
    my $line;
    my $messageid = undef;
    my $buffer = "";
    while (defined($line = <FILE>)) {
	if (!defined($messageid)) {
	    $buffer .= $line;
	    if ($line =~ m/^Message-ID:\s+(<[^>]+>)/) {
		$messageid = $1;
		print "takethis $messageid\015\012";
		print $buffer;
	    }
	} else {
	    print $line;
	}
    }
    close FILE;
}
