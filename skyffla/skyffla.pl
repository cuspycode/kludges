#!/usr/bin/perl

use Socket;
use Getopt::Long;

my $buffer = "";

my $port = $ENV{SKYFFLA_PORT} || 7777;
my $delay = $ENV{SKYFFLA_DELAY} || 0;
my $offset = 0;
my $verbose = 0;
my $size = 1000;
my $host = "localhost";
my $pull = undef;
my $push = undef;
my $slurp = undef;
my $file = undef;
GetOptions('delay=s' => \$delay,
	   'offset=i' => \$offset,
	   'verbose' => \$verbose,
	   'port=i' => \$port,
	   'host=s' => \$pull,
	   'pull=s' => \$pull,
	   'push=s' => \$push,
	   'slurp'  => \$slurp,
	   'file=s' => \$file);

if (defined($pull)) {
    $host = $pull;
    $slurp = 1;
} elsif (defined($push)) {
    $host = $push;
}

my $tcp_proto = getprotobyname("tcp");

sub delay {
    select(undef, undef, undef, $delay);
}

sub skyffla {
    my $bytecount = 0;
    my $starttime = time;
    if (defined($slurp)) {
	while (1) {
	    my $n = sysread(CSOCK, $buffer, $size);
	    last if !defined($n) || $n == 0;
	    syswrite(STDOUT, $buffer, $n);
	    $bytecount += $n;
	    &delay($delay);
	}
    } elsif (defined($file)) {
	open FILE, "<$file" or die "Couldn't open file ${file} : $!";
	sysseek(FILE, $offset, 0);
	while (1) {
	    my $n = sysread(FILE, $buffer, $size);
	    last if !defined($n) || $n == 0;
	    syswrite(CSOCK, $buffer, $n);
	    $bytecount += $n;
	    &delay($delay);
	}
	close(FILE);
    } else {
	while (1) {
	    my $n = sysread(STDIN, $buffer, $size);
	    last if !defined($n) || $n == 0;
	    syswrite(CSOCK, $buffer, $n);
	    $bytecount += $n;
	    &delay($delay);
	}
    }
    if ($verbose) {
	my $timediff = time - $starttime + 1e-43;
	my $bytespersec = $bytecount/$timediff;
	printf STDERR "%d seconds, %.3g Mbyte/s, %.3g Mbps\n",
		$timediff, $bytespersec/1000000, $bytespersec/125000;
    }
    close(CSOCK);
}

if (defined($push) || defined($pull)) {
    socket(CSOCK, PF_INET, SOCK_STREAM, $tcp_proto);
    if (connect(CSOCK, sockaddr_in($port, inet_aton($host)))) {
	&skyffla();
    } else {
	die "No answer from ${host}:${port}";
    }
} else {
    socket(LSOCK, PF_INET, SOCK_STREAM, $tcp_proto);
    setsockopt(LSOCK, SOL_SOCKET, SO_REUSEADDR, pack("l",1));
    bind(LSOCK, sockaddr_in($port, INADDR_ANY));
    listen(LSOCK, 1);

    if (accept(CSOCK, LSOCK)) {
	&skyffla();
    }
    close(LSOCK);
}

1;
