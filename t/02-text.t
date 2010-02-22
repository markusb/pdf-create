#!/usr/bin/perl -w
#
# testing text-related functions
# - string l/r/c
#

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use PDF::Create;
use Test::More tests => 28;

# we want the resulting pdf file to have the same name as the test
my $pdfname = $0;
$pdfname =~ s/\.t/\.pdf/;

###################################################################
#
# start testing
#

my $pdf = new PDF::Create('filename' => "$pdfname",
		  	  'Version'  => 1.2,
			  'PageMode' => 'UseOutlines',
			  'Author'   => 'Markus Baertschi',
			  'Title'    => 'Testing String Functions',
			  'Debug'    => 0,
			);
ok(defined $pdf, "Create new PDF");

ok($pdf->add_comment("The is a PDF for testing"),"Add a comment");

my $root = $pdf->new_page('MediaBox' => $pdf->get_page_size('A4'));
ok(defined $root, "Create page root");

# Prepare font
my $f1 = $pdf->font('Subtype'  => 'Type1',
   	            'Encoding' => 'WinAnsiEncoding',
	            'BaseFont' => 'Helvetica');
ok (defined $f1, "Define Font");

# Add a page which inherits its attributes from $root
my $page = $root->new_page;
ok(defined $root, "Page root defined");

# Page title and description
$page->stringc($f1, 40, 306, 700, 'PDF::Create');
$page->stringc($f1, 20, 306, 650, "version $PDF::Create::VERSION");
$page->stringc($f1, 20, 306, 600, "Test: $0");
$page->stringc($f1, 20, 306, 550, 'Markus Baertschi (markus@markus.org)');

# Use the string functions
ok($page->string($f1, 15, 306, 380, 'Default string'),"string");
ok($page->stringc($f1, 15, 306, 360, 'Centered string (stringc)'),"stringc");
ok($page->stringl($f1, 15, 306, 340, 'Left aligned string (stringl)'),"stringl");
ok($page->stringr($f1, 15, 306, 320, 'Right aligned string (stringr)'),"stringr");

ok($page->string($f1, 15, 306, 280, 'Default string underlined'),"string");
ok($page->string_underline($f1, 15, 306, 280, 'Default string underlined'),"string_underline");
ok($page->string($f1, 15, 306, 260, 'Left string underlined', 'l'),"string l");
ok($page->string_underline($f1, 15, 306, 260, 'Left string underlined','l'),"string_underline l");
ok($page->string($f1, 15, 306, 240, 'Right string underlined', 'r'),"string r");
ok($page->string_underline($f1, 15, 306, 240, 'Right string underlined','r'),"string_underline r");
ok($page->string($f1, 15, 306, 220, 'Centered string underlined', 'c'),"string c");
ok($page->string_underline($f1, 15, 306, 220, 'Centered string underlined','c'),"string_underline c");

# Use the text function
ok($page->text('start'=>1,'Td'=>'200 190','Tf'=>"$f1 9",'TL'=>9,'end'=>1),'text setup');
ok($page->text('text'=>'text with new text function 1'),'text');
ok($page->text('T*'=>1,'text'=>'text with new text function 2','end'=>1),'text');
ok($page->text('start'=>1,'Td'=>'200 160','Tf'=>"$f1 9",'Tr'=>1,'text'=>'text in rendering mode 1','end'=>1),'text');
ok($page->text('start'=>1,'Td'=>'200 150','Tr'=>0,'Tz'=>200,'text'=>'Text Stretched','end'=>1),'text');
ok($page->text('start'=>1,'Tz'=>100,'end'=>1),'text');

ok($page->text('start'=>1,'rot'=>'30 440 100','Tf'=>"$f1 9",'text'=>'text rotated 30','end'=>1),'text');
ok($page->text('start'=>1,'rot'=>'60 420 100','Tf'=>"$f1 9",'text'=>'text rotated 60','end'=>1),'text');
ok($page->text('start'=>1,'rot'=>'90 400 100','Tf'=>"$f1 9",'text'=>'text rotated 90','end'=>1),'text');

# Wrap up the PDF and close the file
ok(!$pdf->close(),"Close PDF");

################################################################
#
# Check the resulting pdf for errors with pdftotext
#
if (-x '/usr/bin/pdftotext') {
  if (my $out=`/usr/bin/pdftotext $pdfname -`) {
    ok(1,"pdf reads fine with pdftotext");
  } else {
    ok(0,"pdftotext reported errors");
    exit 1;
  }
} else {
    skip("Skip: /usr/bin/pdftotext not installed");
}
#
# TODO: Add test with ghostscript
#
#echo | gs -q -sDEVICE=bbox 06-wifi-parabola-broken.pdf
