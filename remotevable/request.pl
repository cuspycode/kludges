#!/usr/bin/perl

use vars qw(%config);
use CGI qw(:standard);
use POSIX;

my $PATHPREFIX = "/srv/www/cgi-bin/removable";
my $WRAPPER = "$PATHPREFIX/setuid-wrapper";

print header('application/xml');

my $param_op = param('op');
my $param_volid = param('volid');

if (request_method eq 'POST' || request_method eq 'GET' && $param_op eq 'list') {
    system {$WRAPPER} $WRAPPER, $param_op, $param_volid;
} else {
    print "<?xml version='1.0' encoding='utf-8'?>\n";
    print "<unrecognized/>\n";
}

