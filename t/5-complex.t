#!/usr/bin/perl -w
#
# page-simple.t
#
# simple test page
#

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use PDF::Create;

print "1..1\n";

my $pdfname = $0;
$pdfname =~ s/\.t/\.pdf/;

my $pdf = new PDF::Create('filename' => "$pdfname",
		  	  'Version'  => 1.2,
			  'PageMode' => 'UseOutlines',
			  'Author'   => 'Markus Baertschi',
			  'Title'    => 'Simple Test Document',
			);

my $root = $pdf->new_page('MediaBox' => $pdf->get_page_size('A4'));

# Prepare 2 fonts
my $f1 = $pdf->font('Subtype'  => 'Type1',
   	            'Encoding' => 'WinAnsiEncoding',
	            'BaseFont' => 'Helvetica');

# Add a page which inherits its attributes from $root
my $page = $root->new_page;

# Write some text to the page
$page->stringc($f1, 40, 306, 700, 'PDF::Create');
$page->stringc($f1, 20, 306, 650, "version $PDF::Create::VERSION");
$page->stringc($f1, 20, 306, 600, 'Simple Test Document');
$page->stringc($f1, 20, 300, 300, 'Fabien Tassin');
$page->stringc($f1, 20, 300, 250, 'Markus Baertschi (markus@markus.org)');

# Wrap up the PDF and close the file
$pdf->close;

print "ok 1 # test $0 ended\n";

