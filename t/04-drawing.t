#!/usr/bin/perl -w
#
# PDF::Create - Test Script
#
# Copyright 2010-     Markus Baertschi <markus@markus.org>
#
# Please see the CHANGES and Changes file for the detailed change log
#
# Testing drawing-related functions
# - line, path, stroke
# - color
#

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use PDF::Create;
use Test::More tests => 21;

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
$page->stringc( $f1, 20, 306, 620, "Test: $0" );
$page->stringc( $f1, 20, 306, 590, 'Markus Baertschi (markus@markus.org)' );

# Draw some graphics
ok( $page->line( 100, 200, 100, 600 ), "line" );
$page->line( 100, 200, 500, 200 );
$page->line( 100, 600, 500, 600 );
$page->line( 500, 200, 500, 600 );
$page->line( 300, 200, 300, 600 );
$page->line( 100, 400, 500, 400 );
for ( my $x = 100 ; $x <= 500 ; $x = $x + 25 ) { $page->line( $x,  395, $x,  405 ); }
for ( my $y = 200 ; $y <= 600 ; $y = $y + 25 ) { $page->line( 295, $y,  305, $y ); }

#ok($page->newpath(),"newp0ath");
#ok($page->setrgbcolorstroke(1, 0.0, 0.0),"setrgbcolorstroke");
ok($page->setrgbcolor(0.1, 0.3, 0.8),"setrgbcolor");
ok($page->set_width(10),"setwidth");
ok($page->moveto(270,100),"moveto");
ok($page->lineto(300,160),"lineto");
ok($page->lineto(330,100),"lineto");
ok($page->lineto(270,100),"lineto");
#ok($page->closepath(),"closepath");
#ok($page->closestroke(),"stroke");
ok($page->fill(),"fill");
ok($page->stroke(),"stroke");

ok( $page->set_width(2), "set_width" );
my ( $x, $y, $x2, $y2 );
ok( $page->newpath, "newpath" );
ok( $page->setrgbcolorstroke( 0.1, 0.2, 1 ), "setrgbcolorstroke" );
ok( $page->moveto( 100, 400 ), "moveto" );
for ( $x = -3.14 ; $x <= 3.14 ; $x = $x + 0.03 ) {
	$y  = sin($x);
	$y2 = 400 + int( $y * 2000 ) / 10;
	$x2 = 300 + int( $x * 2000 / 3.14 ) / 10;
	$page->lineto( $x2, $y2 );
}
ok( $page->stroke, "stroke" );

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
