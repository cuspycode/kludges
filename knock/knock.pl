#!/usr/bin/perl

use Fcntl qw/:DEFAULT :flock/;
use POSIX qw/setsid/;

my $arg = $ARGV[0];
my $DELAY = 300;
my $PORT = "2222";
my $SBIN = "/usr/sbin";
my @RULE_ARGS = ("INPUT", "-p", "tcp", "--destination-port", "$PORT", "-j", "DROP");
my $LOCKFILE_PATH = "/tmp/knock.lockfile";

if (!open FILE, "+>>$LOCKFILE_PATH") {
    die "Couldn't open '$LOCKFILE_PATH': $!";
}
if (!flock FILE, LOCK_EX) {
    die "Couldn't lock '$LOCKFILE_PATH': $!";
}

my $add = 0;
my $del = 0;
my $sleep = 0;

if (!defined($arg)) {
    $add = 1;
    $del = 1;
    $sleep = 1;
} elsif ($arg eq 'del') {
    $del = 1;
} elsif ($arg eq 'add') {
    $add = 1;
}

if ($del) {
    system {"$SBIN/iptables"} "$SBIN/iptables", "-D", @RULE_ARGS;
    system {"$SBIN/ip6tables"} "$SBIN/ip6tables","-D", @RULE_ARGS;
}

if ($add) {
    my $pid = fork();
    if ($pid == 0) {
	setsid();
	if ($sleep) {
	    sleep $DELAY;
	}
	system {"$SBIN/iptables"} "$SBIN/iptables", "-A", @RULE_ARGS;
	system {"$SBIN/ip6tables"} "$SBIN/ip6tables", "-A", @RULE_ARGS;
    } else {
	exit(0);
    }
}

close FILE;

1;
