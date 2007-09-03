#!/usr/bin/perl -w
#
# sample PDF::Create usage
#

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use PDF::Create;

my $pdf = new PDF::Create('filename' => 'sample.pdf',
		   			      'Version'  => 1.2,
					      'PageMode' => 'UseOutlines',
					      'Author'   => 'Fabien Tassin',
						  'Title'    => 'Sample Document',
						);

my $root = $pdf->new_page('MediaBox' => $pdf->get_page_size('A4'));

# Prepare 2 fonts
my $f1 = $pdf->font('Subtype'  => 'Type1',
	 	   	        'Encoding' => 'WinAnsiEncoding',
			        'BaseFont' => 'Helvetica');
my $f2 = $pdf->font('Subtype'  => 'Type1',
			        'Encoding' => 'WinAnsiEncoding',
			        'BaseFont' => 'Helvetica-Bold');

# Prepare a Table of Content
my $toc = $pdf->new_outline('Title' => 'Sample Document');

# Add a page which inherits its attributes from $root
my $page = $root->new_page;
# Add a entry to the outline
$toc->new_outline('Title' => 'Page 1', 'Destination' => $page);

# Write some text to the page
$page->stringc($f2, 40, 306, 426, "PDF::Create");
$page->stringc($f1, 20, 306, 396, "version $PDF::Create::VERSION");
$page->stringc($f1, 20, 300, 300, 'Fabien Tassin');
$page->stringc($f1, 20, 300, 250, 'Markus Baertschi (markus@markus.org)');

# add another page
my $page2 = $root->new_page;
my $s2 = $toc->new_outline('Title' => 'Page 2', 'Destination' => $page2);
$s2->new_outline('Title' => 'GIF');
$s2->new_outline('Title' => 'JPEG');

# Draw a border around the page (A4 max is 595/842)
$page2->line(10, 10, 10, 832);
$page2->line(10, 10, 585, 10);
$page2->line(10, 832, 585, 832);
$page2->line(585, 10, 585, 832);

# Add a gif image
$page2->string($f1, 20, 50, 600, 'GIF Image:');
my $img1 = $pdf->image('pdf-logo.gif');
$page2->image('image'=>$img1, 'xscale'=>0.2,'yscale'=>0.2,'xpos'=>200,'ypos'=>600);

# Add a jpeg image
$page2->string($f1, 20, 50, 500, 'JPEG Image:');
my $img2 = $pdf->image('pdf-logo.jpg');
$page2->image('image'=>$img2, 'xscale'=>0.2,'yscale'=>0.2,'xpos'=>200,'ypos'=>500);

# Wrap up the PDF and close the file
$pdf->close;

