#!/usr/bin/perl

my $rorligt = "$ENV{HOME}/seom-data/rorliga-priser-2024.txt";

open RORLIGT, "<$rorligt"
    or die "Couldn't open file for reading: $rorligt";

my @usage_data = ();
<RORLIGT>;	# discard header line
while (defined(my $line = <RORLIGT>)) {
    chomp $line;
    my @row = split(/\s+/, $line);
    push @usage_data, [@row];
}

close RORLIGT;

my $MY_YEAR = 2024;
my $FEB_DAYS = 29;

my @dayspermonth = (31, $FEB_DAYS, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

print "Dummy Header\n";

foreach my $month (0..11) {
    my ($kwh,$price,$watts,$cert,$mavg,$eavg,$tax) = @{$usage_data[$month]};
    foreach my $mday (1..$dayspermonth[$month]) {
	foreach my $hour (0..23) {
	    my $hourtag = sprintf("%02d/%02d/%04d", $month+1, $mday, $MY_YEAR);
	    my $ampm = "AM";
	    my $h12 = $hour;
	    if ($hour == 12) {
		$ampm = "PM";
	    } elsif ($hour > 12) {
		$h12 = $hour - 12;
		$ampm = "PM";
	    }
	    if ($hour > 0) {
		$hourtag = sprintf("%02d/%02d/%02d %02d:00 %s", $month+1, $mday, $MY_YEAR-2000, $h12, $ampm);
	    }
	    my $moms = 1.25;
	    #my $final = $moms * ($price + $cert/100 + $tax + $eavg/100);
	    my $final = $moms * ($price + $cert + $tax);
	    print "$hourtag,60,0,0,0,0,0,0,0,0,$final\n";
	}
    }
}

