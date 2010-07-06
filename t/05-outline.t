#!/usr/bin/perl -w
#
# PDF::Create - Test Script
#
# Copyright 2010-     Markus Baertschi <markus@markus.org>
#
# Please see the CHANGES and Changes file for the detailed change log
#
# Testing TOC/Outline
#

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use PDF::Create;
use Test::More tests => 13;

# we want the resulting pdf file to have the same name as the test
my $pdfname = $0;
$pdfname =~ s/\.t/\.pdf/;

###################################################################
#
# start testing
#

my $pdf = new PDF::Create( 'filename' => "$pdfname",
						   'Version'  => 1.2,
						   'PageMode' => 'UseOutlines',
						   'Author'   => 'Markus Baertschi',
						   'Title'    => 'Simple Test Document',
						 );
ok( defined $pdf, "Create new PDF" );

ok( $pdf->add_comment("The is a PDF for testing"), "Add a comment" );

my $root = $pdf->new_page( 'MediaBox' => $pdf->get_page_size('A4') );
ok( defined $root, "Create page root" );

# Prepare font
my $f1 = $pdf->font( 'Subtype'  => 'Type1',
					 'Encoding' => 'WinAnsiEncoding',
					 'BaseFont' => 'Helvetica'
				   );
ok( defined $f1, "Define Font" );

# Add a page which inherits its attributes from $root
my $page = $root->new_page;
ok( defined $root, "Page root defined" );

# Write some text to the page
$page->stringc( $f1, 40, 306, 700, 'PDF::Create' );
$page->stringc( $f1, 20, 306, 650, "version $PDF::Create::VERSION" );
$page->stringc( $f1, 20, 306, 600, "Test: $0" );
$page->stringc( $f1, 20, 306, 550, 'Markus Baertschi (markus@markus.org)' );

# Create a Outline/TOC
ok( my $out0 = $pdf->new_outline( 'Title' => 'Title page', 'Destination' => $page ), "new_outline" );

# Some more pages with outline
$page = $root->new_page;
$page->stringc( $f1, 40, 306, 700, 'Section 1' );
ok( my $out1 = $pdf->new_outline( 'Title' => 'Section 1', 'Destination' => $page ), "new_outline" );

$page = $root->new_page;
$page->stringc( $f1, 40, 306, 700, 'Section 2' );
ok( my $out2 = $pdf->new_outline( 'Title' => 'Section 2', 'Destination' => $page ), "new_outline" );

$page = $root->new_page;
$page->stringc( $f1, 40, 306, 700, 'Section 2.1' );
ok( my $out21 = $pdf->new_outline( 'Title' => 'Section 2.1', 'Destination' => $page, 'Parent' => $out2 ),
	"new_outline with parent" );

$page = $root->new_page;
$page->stringc( $f1, 40, 306, 700, 'Section 2.2' );
ok( my $out22 = $pdf->new_outline( 'Title' => 'Section 2.2', 'Destination' => $page, 'Parent' => $out2 ),
	"new_outline with parent" );

$page = $root->new_page;
$page->stringc( $f1, 40, 306, 700, 'Appendix' );
ok( my $app = $pdf->new_outline( 'Title' => 'Appendix', 'Destination' => $page ), "new_outline" );

# Wrap up the PDF and close the file
ok( !$pdf->close(), "Close PDF" );


################################################################
#
# Check the resulting pdf for errors with pdftotext
#
SKIP: {
	skip '/usr/bin/pdftotext not installed', 1 if (! -x '/usr/bin/pdftotext');
    my $out = `/usr/bin/pdftotext $pdfname /dev/null 2>&1`;
    ok( $out eq "", "pdftotext $out");
}

#
# TODO: Add test with ghostscript
#
#echo | gs -q -sDEVICE=bbox 06-wifi-parabola-broken.pdf
