#!/usr/bin/perl -w
#
# PDF::Create - Test Script
#
# Copyright 2010-     Markus Baertschi <markus@markus.org>
#
# Please see the CHANGES and Changes file for the detailed change log
#
# Testing annitations
# - Link
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
						   'Title'    => 'Testing Basic Stuff',
						 );
ok( defined $pdf, "Create new PDF" );

ok( $pdf->add_comment("Testing Basic Stuff"), "Add a comment" );

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

my $uri = 'http://search.cpan.org/~markusb/PDF-Create/';

# Clickable URI with visible box around it
$page->string( $f1, 15, 150, 440, "Clickable Link" );
ok( $page->string( $f1, 15, 150, 400, "$uri" ), "string" );
ok( $page->string_underline( $f1, 15, 150, 400, "$uri" ), "string_underline" );
ok( $pdf->annotation( 'Subtype' => 'Link',
					  'x'       => 145,
					  'y'       => 395,
					  'w'       => 321,
					  'h'       => 25,
					  'URI'     => 'http://search.cpan.org/~markusb/PDF-Create',
					  'Border'  => [ 1, 1, 1 ]
					),
	"annotation"
  );

# Clickable URI with invisible box around it
$page->stringc( $f1, 15, 306, 240, "Clickable Link Centered" );
ok( $page->string( $f1, 15, 306, 200, "$uri", 'c' ), "string" );
ok( my $len = $page->string_underline( $f1, 15, 306, 200, "$uri", 'c' ), "string_underline" );
ok( $pdf->annotation( 'Subtype' => 'Link',
					  'x'       => 306 - ( $len / 2 ),
					  'y'       => 200,
					  'w'       => $len,
					  'h'       => 15,
					  'URI'     => 'http://search.cpan.org/~markusb/PDF-Create',
					  'Border'  => [ 0, 0, 0 ]
					),
	"annotation"
  );

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
