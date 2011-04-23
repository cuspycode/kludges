#!/usr/bin/perl

my $op = $ARGV[0];
my $volid = $ARGV[1];

die "null arg" unless defined($op) && defined($volid);

my $MOUNTROOT = "/removable";

my %mountpoints = ();
opendir DIR, $MOUNTROOT or die "couldn't open $MOUNTROOT: $!";
my @names = readdir(DIR);
closedir DIR;
foreach (@names) {
    if (m/^[^.]/ and -d "$MOUNTROOT/$_") {
	$mountpoints{$_} = 1;
    }
}

my @online = ();
opendir DIR, "/dev/disk/by-label" or die "couldn't open /dev/disk/by-label: $!";
my @names = readdir(DIR);
closedir DIR;
foreach (@names) {
    if ($mountpoints{$_}) {
	push @online, $_;
    }
}
@online = sort @online;

my %mounted = ();
open FILE, "</proc/mounts" or die "couldn't open /proc/mounts: $!";
my @lines = <FILE>;
close FILE;
foreach (@lines) {
    if (m{ \Q$MOUNTROOT\E/(\S+)}) {
	$mounted{$1} = 1;
    }
}

if ($op eq 'mount') {
    print "<?xml version='1.0' encoding='utf-8'?>\n";
    print "<response>\n";
    if ($mountpoints{$volid}) {
	my $status = system {"/bin/mount"} "/bin/mount", "$MOUNTROOT/$volid";
	if ($status == 0) {
	    print "<ok/>\n";
	} else {
	    print "<error>Mount failed</error>\n";
	}
    } else {
	print "<error>Unrecognized volume</error>\n";
    }
    print "</response>\n";

} elsif ($op eq 'unmount') {
    print "<?xml version='1.0' encoding='utf-8'?>\n";
    print "<response>\n";
    if ($mountpoints{$volid}) {
	my $status = system {"/bin/umount"} "/bin/mount", "$MOUNTROOT/$volid";
	if ($status == 0) {
	    print "<ok/>\n";
	} else {
	    print "<error>Unmount failed</error>\n";
	}
    } else {
	print "<error>Unrecognized volume</error>\n";
    }
    print "</response>\n";

} elsif ($op eq 'list') {
    print "<?xml version='1.0' encoding='utf-8'?>\n";
    print "<response>\n";
    if ($volid eq 'all') {
	foreach my $name (sort keys %mountpoints) {
	    my $extra = "";
	    $extra .= " online" if $online{$name};
	    $extra .= " mounted" if $mounted{$name};
	    print "   <volume>$name$extra</volume>\n";
	}
    } elsif ($volid eq 'mounted') {
	foreach my $name (@online) {
	    if ($mounted{$name}) {
		print "   <volume>$name</volume>\n";
	    }
	}
    } elsif ($volid eq 'unmounted') {
	foreach my $name (@online) {
	    if (!$mounted{$name}) {
		print "   <volume>$name</volume>\n";
	    }
	}
    }
    print "</response>\n";
} else {
    die "illegal op '$op'";
}

