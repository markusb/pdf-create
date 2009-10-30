#!/usr/bin/perl -w
#
# Print some text with each of the supported fonts
#

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use PDF::Create;

my $testnum=1;
print "1..5\n";

my $pdfname = $0;
$pdfname =~ s/\.t/\.pdf/;

my $pdf = new PDF::Create('filename' => "$pdfname",
		  	  'Version'  => 1.2,
			  'PageMode' => 'UseOutlines',
			  'Author'   => 'Markus Baertschi',
			  'Title'    => 'Simple Test Document',
			);
if ($pdf) { printf "ok %d # pdf created\n",$testnum++; }
else { print "Bail out!  # pdf creation failed\n"; }

my $root = $pdf->new_page('MediaBox' => $pdf->get_page_size('A4'));
if ($root) { printf "ok %d # root page created\n",$testnum++; }
else { print "Bail out! # root page creation failed\n"; }

# Prepare fonts
my %font;
my $f_helv = define_font('Helvetica');
$font{'Courier'} = define_font('Courier');
$font{'Courier-Bold'} = define_font('Courier-Bold');
$font{'Courier-Oblique'} = define_font('Courier-Oblique');
$font{'Courier-BoldOblique'} = define_font('Courier-BoldOblique');
$font{'Helvetica'} = define_font('Helvetica');
$font{'Helvetica-Bold'} = define_font('Helvetica-Bold');
$font{'Helvetica-Oblique'} = define_font('Helvetica-Oblique');
$font{'Helvetica-BoldOblique'} = define_font('Helvetica-BoldOblique');
$font{'Times-Roman'} = define_font('Times-Roman');
$font{'Times-Bold'} = define_font('Times-Bold');
$font{'Times-Italic'} = define_font('Times-Italic');
$font{'Times-BoldItalic'} = define_font('Times-BoldItalic');

# Add a page which inherits its attributes from $root
my $page = $root->new_page;
if ($root) { printf "ok %d # page defined\n",$testnum++; }
else { printf "not ok %d # page definition failed\n",$testnum++; }

# Write some text to the page
$page->stringc($f_helv, 40, 306, 700, 'PDF::Create');
$page->stringc($f_helv, 20, 306, 670, "version $PDF::Create::VERSION");
$page->stringc($f_helv, 30, 306, 630, 'List of Supported Fonts');
$page->stringc($f_helv, 20, 300, 560, 'Markus Baertschi (markus@markus.org)');

my $y = 500;
foreach my $f (sort keys %font) {
#  printf "ok %d # printing line in $f at pos $y\n",$testnum++;
  $page->stringc($font{$f}, 20, 300, $y, $f);
  $y -= 30;
}
    
# Wrap up the PDF and close the file
$pdf->close;

# Check the resulting pdf for errors with pdftotext
if (-x '/usr/bin/pdftotext') {
  if (my $out=`/usr/bin/pdftotext $pdfname -`) {
    printf "ok %d # pdf reads fine with pdftotext\n",$testnum++;
  } else {
    printf "not ok %d # pdftotext reported errors\n",$testnum++;
    exit 1;
  }
} else {
  printf "ok %d # Warning: /usr/bin/pdftotext not installed",$testnum++;
}

printf "ok %d \# test $0 ended\n",$testnum++;

exit;

sub define_font {
  my $fname = shift;
  my $ftype = shift;
  my $fencoding = shift;
  if (! defined $ftype) { $ftype = 'Type1'; }
  if (! defined $fencoding) { $fencoding = 'WinAnsiEncoding'; }

  my $f = $pdf->font( 'BaseFont' => $fname,
		      'Subtype'  => $ftype,
		      'Encoding' => $fencoding );
  if ($f) {
#    printf "ok %d # Font '%s' defined\n",$testnum++,$fname;
  } else {
#    print
#    printf "not ok %d # Font '%s' failed\n",$testnum++,$fname;
  }
  return $f;
}

