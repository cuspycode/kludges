#!/usr/bin/perl

my $PLOTUSAGE = $ARGV[0];
my $QUADRIMESTER = $ARGV[1];
my $BATSHIFT = $ENV{BATSHIFT};

my $count = 0;
my $sum = 0;

sub read_prices {
    my $filename = shift;
    my %prices = ();

    open PRICES, "<$filename"
	or die "Couldn't open $filename";

    my $prev_tag = undef;
    while (defined(my $line = <PRICES>)) {
	if ($line =~ m/^([0-9][^,]+),(.+)$/) {
	    my ($tag,@vals) = ($1,split(/,/,$2));
	    my $hour = "00";
	    my $minute = "00";
	    if ($tag =~ m{^(\d\d)/(\d\d)/(\d\d\d\d)$}) {
		if ($prev_tag && substr($prev_tag,11,2) eq "22") {
		    $tag = "$3-$1-$2 23";		# Hack for end of DST
		} else {
		    $tag = "$3-$1-$2 $hour";
		}
	    } elsif ($tag =~ m{^(\d\d)/(\d\d)/(\d\d) (\d\d):(\d\d) (AM|PM)$}) {
		if ($6 eq "PM" && $4 < 12) {
		    $hour = sprintf("%02d", $4 + 12);
		} elsif ($6 eq "AM" && $4 == 12) {
		    $hour = "00";
		} else {
		    $hour = $4;
		}
		$tag = "20$3-$1-$2 $hour";
	    }
	    $prices{$tag} = $vals[9];
	    $prev_tag = $tag;
	}
    }

    close PRICES;

    return \%prices;
}

sub read_usage {
    my $filename = shift;
    my %usage = ();

    open USAGE, "<$filename"
	or die "Couldn't open $filename";

    <USAGE>;
    while (defined(my $line = <USAGE>)) {
	if ($line =~ m/^("[0-9][^"]+");("[^"]+");"Normalt"$/) {
	    my ($tag,$untrimmed) = ($1,$2);
	    my $val = $untrimmed;
	    $val =~ s/"//g;
	    $val =~ s/,/./;
	    $tag = substr($tag,1,13);
	    $usage{$tag} = $val;
	}
     }
     close USAGE;
     return \%usage;
}

my $prices = &read_prices("$ENV{HOME}/seom-data/timpriser-pa-el-solceller-inkl-paslag-jan25.csv");
#my $prices = &read_prices("$ENV{HOME}/seom-data/gen-static-prices.txt");
my $usage = &read_usage("$ENV{HOME}/seom-data/seom-el-2024.csv");

if (defined($BATSHIFT) && $BATSHIFT) {
   my @adjust = (1.8,1.8,1.6,1.2,  0.6,0.6,0.6,0.6,  0.5,0.8,1.1,1.7);
    foreach my $tag (sort keys %$usage) {
	if ($tag =~ m/\d\d\d\d-(\d\d)-\d\d (\d\d)/) {
	    my $adjust = $adjust[$1-1];
	    my $x = $2;
	    if ($x == 0|| $x == 1 || $x == 2 || $x == 3 || $x == 4 || $x == 5) {
		$$usage{$tag} += $adjust*15/6;	# kWh
	    } elsif ($x == 7 || $x == 8 || $x == 9 || $x == 10 || $x == 11 || $x == 12 || $x == 13 || $x == 14 || $x == 15 || $x == 16 || $x == 17 || $x == 18 || $x == 19 || $x == 20 || $x == 21) {
		$$usage{$tag} -= $adjust;	# kWh
	    }
 print "# $tag: $adjust\n" if $$usage{$tag} <= 0;
 print "# Negative usage! ", $$usage{$tag}, " for $tag\n" if $$usage{$tag} <= 0;
	    my $y = $$usage{$tag};
	}
    }
}

if (0) {
foreach my $tag (sort keys %$prices) {
    print $tag, ": ", $$prices{$tag},"\n" if $tag =~ m/2024-12-23/;
    $sum += $$prices{$tag};
    $count++;
}
}

if (0) {
foreach my $tag (sort keys %$usage) {
    print $tag, ": ", $$usage{$tag},"\n";
    $sum += $$usage{$tag};
    $count++;
}
my $mean = $sum/$count;
print "\ncount=$count, mean=$mean\n";
}

my $datafile = "/tmp/seom-plot.txt";
open DATA, ">$datafile" or die "Couldn't open file: $datafile";

my @months = ();
if ($QUADRIMESTER == 1) {
    @months = ("jan","feb","mar","apr");
} elsif ($QUADRIMESTER == 2) {
    @months = ("may","jun","jul","aug");
} elsif ($QUADRIMESTER == 3) {
    @months = ("sep","oct","nov","dec");
}

print DATA "time ".join(" ",@months)."\n";
foreach my $hour (0..24) {
    my @mm = ();
    foreach my $i (0..3) {
	my $month = $i+1+4*($QUADRIMESTER-1);
	my $sum = 0;
	my $count = 0;
	foreach my $day (1..31) {
	    my $tag = "2024-".sprintf("%02d-%02d %02d",$month,$day,$hour);
 if (!$PLOTUSAGE) {
	    if (exists($$prices{$tag})) {
		$count++;
		$sum += $$prices{$tag};
	    }
 } elsif ($PLOTUSAGE) {
	    if (exists($$usage{$tag})) {
		$count++;
		$sum += $$usage{$tag};
	    }
 }
	}
	push @mm, sprintf("%.3f",$sum/$count) unless $count == 0;
    }
    print DATA sprintf("%02d:00 ", $hour), join(" ",@mm),"\n" if @mm;
}

close DATA;

my $YRANGEMAX = ($PLOTUSAGE? 8 : 200);

print qx(ploticus -prefab chron -svg -o /tmp/seom-plot.svg -scale 1,1.5 \\
	data=/tmp/seom-plot.txt \\
	header="yes" xstubfmt=hh x=1 y=2 y2=3 y3=4 y4=5 \\
	unittype=time \\
	yrange="0 $YRANGEMAX" ygrid="color=gray(0.8) style=1 dashscale=1" \\
	legendfmt=singleline mode=line stubvert=no);

my $ycost = 0;
my $mcost = 0;
my $last_month = "";
my $last_tag = "";

foreach my $tag (sort keys %$usage) {
    if (substr($tag,0,7) ne $last_month) {
	printf "%s %8.2f\n", $last_tag, $mcost/100 if $last_month;
	$ycost += $mcost;
	$mcost = 0;
	$last_month = substr($tag,0,7);
    }
    my $u = $$usage{$tag};
    my $p = $$prices{$tag};
    #printf "%s %8.2f\n", $tag, $p*$u;
    $mcost += $p*$u;
    $last_tag = $tag;
}
$ycost += $mcost;
printf "%s %8.2f\n", $last_tag, $mcost/100;
printf "\nTotal:        %8.2f\n", $ycost/100;

