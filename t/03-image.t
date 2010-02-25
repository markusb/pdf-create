#!/usr/bin/perl -w
#
# PDF::Create - Test Script
#
# Copyright 2010-     Markus Baertschi <markus@markus.org>
#
# Please see the CHANGES and Changes file for the detailed change log
#
# Testing image-related functions
# - image
# - JPEG/GIF
#

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use PDF::Create;
use File::Basename;
use Test::More tests => 9;

# we want the resulting pdf file to have the same name as the test
my $pdfname = $0;
$pdfname =~ s/\.t/\.pdf/;
my $gifname = dirname($0) . "/pdf-logo.gif";
my $jpgname = dirname($0) . "/pdf-logo.jpg";

###################################################################
#
# start testing
#

my $pdf = new PDF::Create( 'filename' => "$pdfname",
						   'Version'  => 1.2,
						   'PageMode' => 'UseOutlines',
						   'Author'   => 'Markus Baertschi',
						   'Title'    => 'Testing Images (jpg, gif)',
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

# Add a JPEG image
$page->string( $f1, 20, 200, 400, 'JPEG Image:' );
my $jpg1 = $pdf->image($jpgname);
ok( $page->image( 'image' => $jpg1, 'xscale' => 0.2, 'yscale' => 0.2, 'xpos' => 350, 'ypos' => 400 ), "jpg created" );

# Add a GIF image
$page->string( $f1, 20, 200, 200, 'GIF Image:' );
my $gif1 = $pdf->image($gifname);
ok( $page->image( 'image' => $gif1, 'xscale' => 0.2, 'yscale' => 0.2, 'xpos' => 350, 'ypos' => 200 ), "gif created" );

# Wrap up the PDF and close the file
ok( !$pdf->close(), "Close PDF" );

################################################################
#
# Check the resulting pdf for errors with pdftotext
#
SKIP: {
	skip '/usr/bin/pdftotext not installed', 1 if (! -x '/usr/bin/pdftotext');

	if ( my $out = `/usr/bin/pdftotext $pdfname -` ) {
		ok( 1, "pdf reads fine with pdftotext" );
	} else {
		ok( 0, "pdftotext reported errors" );
		exit 1;
	}
}

#
# TODO: Add test with ghostscript
#
#echo | gs -q -sDEVICE=bbox 06-wifi-parabola-broken.pdf
