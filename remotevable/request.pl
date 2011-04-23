#!/usr/bin/perl

use vars qw(%config);
use CGI qw(:standard);
use POSIX;

my $PATHPREFIX = "/srv/www/cgi-bin/removable";
###do "$PATHPREFIX/request.conf" or die "Failed reading configuration file";	# Is this needed?

my $WRAPPER = "$PATHPREFIX/setuid-wrapper";

print header('application/xml');

my $param_op = param('op');
my $param_volid = param('volid');

if (request_method eq 'POST') {
    system {$WRAPPER} $param_op, $param_volid;
} else {
    print "<?xml version='1.0' encoding='utf-8'?>\n";
    print "<unrecognized/>\n";
}

