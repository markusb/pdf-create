#!/usr/bin/perl -w
#
# 09-cgi.t
#
# cgi test script
#
# run the cgi-test and check the resulting output
#

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use File::Basename;
use PDF::Create;
use Test::More tests => 2;

my $pdfname = $0;
$pdfname =~ s/\.t/\.pdf/;
my $cginame = dirname($0) . "/09-cgi-script.pl";

#
# run the cgi
#
ok( !system("$cginame | sed -n '3,\$p' >$pdfname"), "CGI executes" );

# Check the resulting pdf for errors with pdftotext
SKIP: {
	skip '/usr/bin/pdftotext not installed', 1 if (! -x '/usr/bin/pdftotext');

	if ( my $out = `/usr/bin/pdftotext $pdfname -` ) {
		ok( 1, "pdf reads fine with pdftotext" );
	} else {
		ok( 0, "pdftotext reported errors" );
		exit 1;
	}
}

