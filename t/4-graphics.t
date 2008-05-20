#!/usr/bin/perl -w
#
# 01-simple.t
#
# simple test page
#

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use PDF::Create;

print "1..1\n";

my $pdf = new PDF::Create('filename' => '4-graphics.pdf',
		  	  'Version'  => 1.2,
			  'PageMode' => 'UseOutlines',
			  'Author'   => 'Markus Baertschi',
			  'Title'    => 'Simple Graphics Document',
			);

my $root = $pdf->new_page('MediaBox' => $pdf->get_page_size('A4'));

# Prepare 2 fonts
my $f1 = $pdf->font('Subtype'  => 'Type1',
   	            'Encoding' => 'WinAnsiEncoding',
	            'BaseFont' => 'Helvetica');

# Add a page which inherits its attributes from $root
my $page = $root->new_page;

# Write some text to the page
$page->stringc($f1, 40, 306, 750, 'PDF::Create');
$page->stringc($f1, 20, 306, 710, "version $PDF::Create::VERSION");
$page->stringc($f1, 20, 306, 680, 'Simple Graphics Document');
$page->stringc($f1, 20, 300, 150, 'Fabien Tassin');
$page->stringc($f1, 20, 300, 130, 'Markus Baertschi (markus@markus.org)');

# Draw some graphics
$page->line(100, 200, 100, 600);
$page->line(100, 200, 500, 200);
$page->line(100, 600, 500, 600);
$page->line(500, 200, 500, 600);
$page->line(300, 200, 300, 600);
$page->line(100, 400, 500, 400);
for (my $x = 100; $x<=500; $x=$x+25) { $page->line($x, 395, $x, 405); }
for (my $y = 200; $y<=600; $y=$y+25) { $page->line(295, $y, 305, $y); }

$page->set_width(2);
my ($x,$y,$x2,$y2);
$page->newpath;
$page->setrgbcolorstroke(0.1,0.2,1);
$page->moveto(100,400);
for ($x = -3.14; $x<=3.14; $x=$x+0.03) {
  $y=sin($x);
  $y2=400+int($y*2000)/10;
  $x2=300+int($x*2000/3.14)/10;
  $page->lineto($x2,$y2);
}
$page->stroke;

# Wrap up the PDF and close the file
$pdf->close;

print "ok 1 # test $0 ended\n";

