#!/usr/bin/perl

my $op = $ARGV[0];
my $volid = $ARGV[1];

die "null arg" unless defined($op) && defined($volid);

####my $MOUNTROOT = "/removable";
my $MOUNTROOT = "/media";

my %mountpoints = ();
opendir DIR, $MOUNTROOT or die "couldn't open $MOUNTROOT: $!";
my @names = readdir(DIR);
closedir DIR;
foreach (@names) {
    if (m/^[^.]/ and -d "$MOUNTROOT/$_") {
	$mountpoints{$_} = 1;
    }
}

print "<?xml version='1.0' encoding='utf-8'?>\n";
print "<response>\n";

if ($op eq 'mount') {
} elsif ($op eq 'unmount') {
} elsif ($op eq 'list') {
    foreach my $name (sort keys %mountpoints) {
	print "   <volume>$name</volume>\n";
    }
} else {
    die "illegal op '$op'";
}

print "</response>\n";

