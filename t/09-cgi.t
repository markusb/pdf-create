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

print "1..3\n";

my $pdfname = $0;
$pdfname =~ s/\.t/\.pdf/;
my $cginame = dirname($0) . "/09-cgi-script.pl";

#
# run the cgi
#
if ( system("$cginame | sed -n '3,\$p' >$pdfname") ) {
	print "Bail out: Could not run cgi-script $cginame\n";
} else {
	print "ok 1 # cgi-script executed\n";
}

# Check the resulting pdf for errors with pdftotext
if ( -x '/usr/bin/pdftotext' ) {
	if ( my $out = `/usr/bin/pdftotext $pdfname -` ) {
		print "ok 2 # pdf reads fine with pdftotext\n";
	} else {
		print "not ok 2 # pdftotext reported errors\n";
		exit 1;
	}
} else {
	print "ok 2 # Warning: /usr/bin/pdftotext not installed";
}
print "ok 3 \# test $0 ended\n";
