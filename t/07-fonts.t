#!/usr/bin/perl -w
#
# PDF::Create - Test Script
#
# Copyright 2010-     Markus Baertschi <markus@markus.org>
#
# Please see the CHANGES and Changes file for the detailed change log
#
# Testing fonts
#

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use PDF::Create;
use Test::More tests => 32;

# we want the resulting pdf file to have the same name as the test
my $pdfname = $0;
$pdfname =~ s/\.t/\.pdf/;

###################################################################
#
# start testing
#

my $pdf = PDF::Create->new( 'filename' => "$pdfname",
						   'Version'  => 1.2,
						   'PageMode' => 'UseOutlines',
						   'Author'   => 'Markus Baertschi',
						   'Title'    => 'Testing Basic Stuff',
						 );
ok( defined $pdf, "Create new PDF" );

ok( $pdf->add_comment("Testing Fonts"), "Add a comment" );

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

# Prepare fonts
my %font;
my $f_helv = define_font('Helvetica');
$font{'Courier'}               = define_font('Courier');
$font{'Courier-Bold'}          = define_font('Courier-Bold');
$font{'Courier-Oblique'}       = define_font('Courier-Oblique');
$font{'Courier-BoldOblique'}   = define_font('Courier-BoldOblique');
$font{'Helvetica'}             = define_font('Helvetica');
$font{'Helvetica-Bold'}        = define_font('Helvetica-Bold');
$font{'Helvetica-Oblique'}     = define_font('Helvetica-Oblique');
$font{'Helvetica-BoldOblique'} = define_font('Helvetica-BoldOblique');
$font{'Times-Roman'}           = define_font('Times-Roman');
$font{'Times-Bold'}            = define_font('Times-Bold');
$font{'Times-Italic'}          = define_font('Times-Italic');
$font{'Times-BoldItalic'}      = define_font('Times-BoldItalic');

my $y = 500;
foreach my $f ( sort keys %font ) {
	ok( $page->stringc( $font{$f}, 20, 300, $y, $f ), "Writing with font $f" );
	$y -= 30;
}

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

exit;

sub define_font
{
	my $fname     = shift;
	my $ftype     = shift;
	my $fencoding = shift;
	if ( !defined $ftype )     { $ftype     = 'Type1'; }
	if ( !defined $fencoding ) { $fencoding = 'WinAnsiEncoding'; }

	ok( my $f = $pdf->font( 'BaseFont' => $fname,
							'Subtype'  => $ftype,
							'Encoding' => $fencoding
						  ),
		"Defining font $fname"
	  );
	return $f;
}

