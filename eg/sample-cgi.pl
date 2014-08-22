#!/usr/bin/perl -w
#
# sample PDF::Create usage for a Web CGI
#
# Inpired by alr with a CPAN annotation
#

use strict;
use PDF::Create;
use CGI;

# CGI Header designating the pdf data
print CGI::header( -type => 'application/x-pdf',
		   -attachment => 'sample.pdf' );

# Open pdf to stdout
my $pdf = new PDF::Create('filename' => '-', # STDOUT
			  'Version'  => 1.2,
			  'PageMode' => 'UseOutlines',
			  'Author'   => 'John Doe',
			  'Title'    => 'Sample Document',
			 );

my $page = $pdf->new_page('MediaBox' => $pdf->get_page_size('a4'));

# Prepare 2 fonts
my $f1 = $pdf->font('Subtype'  => 'Type1',
	 	    'Encoding' => 'WinAnsiEncoding',
		    'BaseFont' => 'Helvetica');
my $f2 = $pdf->font('Subtype'  => 'Type1',
		    'Encoding' => 'WinAnsiEncoding',
		    'BaseFont' => 'Helvetica-Bold');

# Prepare a Table of Content
my $toc = $pdf->new_outline('Title' => 'Sample Document');

# Add a entry to the outline
$toc->new_outline('Title' => 'Page 1', 'Destination' => $page);

# Write some text to the page
$page->stringc($f2, 40, 306, 426, "PDF::Create");
$page->stringc($f1, 20, 306, 396, "version $PDF::Create::VERSION");
$page->stringc($f1, 20, 300, 300, 'Fabien Tassin');
$page->stringc($f1, 20, 300, 250, 'Markus Baertschi (markus@markus.org)');
$page->stringc($f1, 20, 300, 200, 'sample-cgi.pl');

# Wrap up the PDF and close the file
$pdf->close;

