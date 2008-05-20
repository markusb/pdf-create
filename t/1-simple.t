#!/usr/bin/perl -w
#
# 01-simple.t
#
# simple test page
#

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use PDF::Create;

print "1..5\n";

my $pdf = new PDF::Create('filename' => 'simple.pdf',
		  	  'Version'  => 1.2,
			  'PageMode' => 'UseOutlines',
			  'Author'   => 'Markus Baertschi',
			  'Title'    => 'Simple Test Document',
			);
if ($pdf) { print "ok 1 # pdf created\n";
} else { print "Bail out!  # pdf creation failed\n"; }

my $root = $pdf->new_page('MediaBox' => $pdf->get_page_size('A4'));
if ($root) { print "ok 2 # root page created\n";
} else { print "Bail out! # root page creation failed\n"; }

# Prepare 2 fonts
my $f1 = $pdf->font('Subtype'  => 'Type1',
   	            'Encoding' => 'WinAnsiEncoding',
	            'BaseFont' => 'Helvetica');
if ($f1) { print "ok 3 # font defined\n";
} else { print "not ok 3 # font definition failed\n"; }

# Add a page which inherits its attributes from $root
my $page = $root->new_page;
if ($root) { print "ok 4 # page defined\n";
} else { print "not ok 4 # page definition failed\n"; }

# Write some text to the page
$page->stringc($f1, 40, 306, 700, 'PDF::Create');
$page->stringc($f1, 20, 306, 650, "version $PDF::Create::VERSION");
$page->stringc($f1, 20, 306, 600, 'Simple Test Document');
$page->stringc($f1, 20, 300, 300, 'Fabien Tassin');
$page->stringc($f1, 20, 300, 250, 'Markus Baertschi (markus@markus.org)');

# Wrap up the PDF and close the file
$pdf->close;

print "ok 5 \# test $0 ended\n";
