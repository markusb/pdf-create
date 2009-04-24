#!/usr/bin/perl -w
#
# page-jpeg.t
#
# simple test page with jpeg image
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
			  'Title'    => 'Simple GIF Test Document',
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
$page->stringc($f1, 20, 306, 600, 'Simple GIF Test Document');
$page->stringc($f1, 20, 300, 300, 'Fabien Tassin');
$page->stringc($f1, 20, 300, 250, 'Markus Baertschi (markus@markus.org)');

# Add a JPEG image
$page->string($f1, 20, 200, 400, 'GIF Image:');
my $img1 = $pdf->image('pdf-logo.gif');
$page->image('image'=>$img1, 'xscale'=>0.2,'yscale'=>0.2,'xpos'=>350,'ypos'=>400);

# Wrap up the PDF and close the file
$pdf->close;

print "ok 1 # test $0 ended\n";
