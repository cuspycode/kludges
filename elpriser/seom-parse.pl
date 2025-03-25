#!/usr/bin/perl

my $PLOTUSAGE = 1;

my $count = 0;
my $sum = 0;

sub read_prices {
    my $filename = shift;
    my %prices = ();

    open PRICES, "<$filename"
	or die "Couldn't open $filename";

    while (defined(my $line = <PRICES>)) {
	if ($line =~ m/^([0-9][^,]+),(.+)$/) {
	    my ($tag,@vals) = ($1,split(/,/,$2));
	    my $hour = "00";
	    my $minute = "00";
	    if ($tag =~ m{^(\d\d)/(\d\d)/(\d\d\d\d)$}) {
		$tag = "$3-$1-$2 $hour";
	    } elsif ($tag =~ m{^(\d\d)/(\d\d)/(\d\d) (\d\d):(\d\d) (AM|PM)$}) {
		$hour = ($6 eq "PM" && $4 < 12? sprintf("%02d", $4 + 12) : $4);
		$tag = "20$3-$1-$2 $hour";
	    }
	    $prices{$tag} = $vals[9];
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

my $prices = &read_prices("seom-data/timpriser-pa-el-solceller-inkl-paslag-jan25.csv");
my $usage = &read_usage("seom-data/seom-el-2024.csv");

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
#my @months = ("jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec");
#my @months = ("may","jun","jul","aug","sep","oct","nov","dec");
my @months = ("sep","oct","nov","dec");
print DATA "time ".join(" ",@months)."\n";
foreach my $hour (0..24) {
    my @mm = ();
    #foreach my $month (1..12) {
    #foreach my $month (5..12) {
    foreach my $month (9..12) {
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

my $YRANGEMAX = ($PLOTUSAGE? 5 : 200);

print qx(ploticus -prefab chron -svg -o /tmp/seom-plot.svg -scale 1,1.5 \\
	data=/tmp/seom-plot.txt \\
	header="yes" xstubfmt=hh x=1 y=2 y2=3 y3=4 y4=5 \\
	unittype=time \\
	yrange="0 $YRANGEMAX" ygrid="color=gray(0.8) style=1 dashscale=1" \\
	legendfmt=singleline mode=line stubvert=no);
