#!/usr/bin/perl

########################################################################
#                                                                      #
# TFTP-put over TCP.                                                   #
#                                                                      #
# This is the client part of a TFTP protocol replacement for the       #
# case where only "put" commands are used. The program exits after     #
# one single put command has been processed, which must be in exactly  #
# the format specified by the regexp in the code. The port to connect  #
# to may be specified with the command-line argument -p <port>.        #
#                                                                      #
########################################################################

use Socket;
use Getopt::Std;

my %opt = ();
getopts('p:', \%opt);

my $port = $opt{p} || "tftp";
my $host = $ARGV[0] || die "No remote host specified";

my $tcp_proto = getprotobyname("tcp");
$port = getservbyname($port, "tcp") unless $port =~ m/^\d+$/;

my $cmd = <STDIN>;

if ($cmd =~ m/^put (\S+) (\S+)/) {
    my $file = $1;
    my $dest = $2;
    socket(CSOCK, PF_INET, SOCK_STREAM, $tcp_proto);
    if (connect(CSOCK, sockaddr_in($port, inet_aton($host)))) {
	open FILE, "<$file" or die "Couldn't open file $file\n$!";
	syswrite(CSOCK, "Kaka $dest\n");
	my $buffer = "";
	my $size = 32768;
	while (1) {
	    my $n = sysread(FILE, $buffer, $size);
	    last if !defined($n) || $n == 0;
	    syswrite(CSOCK, $buffer, $n);
	}
	close(FILE);
	close(CSOCK);
    } else {
	die "No answer from $host:$port";
    }
} else {
    die "Unrecognized command '$cmd'";
}

1;
