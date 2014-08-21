use strict;
use warnings;

use File::Temp qw(tempdir);
use PDF::Create;
use Test::More;
use Test::LeakTrace;

plan tests => 4;

my $dir = tempdir( CLEANUP => 1 );

no_leaks_ok {
    my $pdf = PDF::Create->new('filename' => "$dir/mypdf.pdf",
                              'Version'  => 1.2,
                              'PageMode' => 'UseOutlines',
                              'Author'   => 'Fabien Tassin',
                              'Title'    => 'My title',
                         );
};

no_leaks_ok {
    my $pdf = PDF::Create->new('filename' => "$dir/mypdf.pdf",
                              'Version'  => 1.2,
                              'PageMode' => 'UseOutlines',
                              'Author'   => 'Fabien Tassin',
                              'Title'    => 'My title',
                         );
    my $root = $pdf->new_page('MediaBox' => [ 0, 0, 612, 792 ]);
};

no_leaks_ok {
    my $pdf = PDF::Create->new('filename' => "$dir/mypdf.pdf",
                              'Version'  => 1.2,
                              'PageMode' => 'UseOutlines',
                              'Author'   => 'Fabien Tassin',
                              'Title'    => 'My title',
                         );
    my $root = $pdf->new_page('MediaBox' => [ 0, 0, 612, 792 ]);

    # Add a page which inherits its attributes from $root
    my $page = $root->new_page;

    # Prepare 2 fonts
    my $f1 = $pdf->font('Subtype'  => 'Type1',
                        'Encoding' => 'WinAnsiEncoding',
                        'BaseFont' => 'Helvetica');
    my $f2 = $pdf->font('Subtype'  => 'Type1',
                        'Encoding' => 'WinAnsiEncoding',
                        'BaseFont' => 'Helvetica-Bold');

	#$DB::signal = 1;
    # Prepare a Table of Content
    my $toc = $pdf->new_outline('Title' => 'Document',
                                'Destination' => $page);
};

 
no_leaks_ok {
    my $pdf = PDF::Create->new('filename' => "$dir/mypdf.pdf",
                              'Version'  => 1.2,
                              'PageMode' => 'UseOutlines',
                              'Author'   => 'Fabien Tassin',
                              'Title'    => 'My title',
                         );
    my $root = $pdf->new_page('MediaBox' => [ 0, 0, 612, 792 ]);

    # Add a page which inherits its attributes from $root
    my $page = $root->new_page;

    # Prepare 2 fonts
    my $f1 = $pdf->font('Subtype'  => 'Type1',
                        'Encoding' => 'WinAnsiEncoding',
                        'BaseFont' => 'Helvetica');
    my $f2 = $pdf->font('Subtype'  => 'Type1',
                        'Encoding' => 'WinAnsiEncoding',
                        'BaseFont' => 'Helvetica-Bold');

    # Prepare a Table of Content
    my $toc = $pdf->new_outline('Title' => 'Document',
                                'Destination' => $page);
    $toc->new_outline('Title' => 'Section 1');
    my $s2 = $toc->new_outline('Title' => 'Section 2',
                               'Status' => 'closed');
    $s2->new_outline('Title' => 'Subsection 1');

    $page->stringc($f2, 40, 306, 426, "PDF::Create");
    $page->stringc($f1, 20, 306, 396, "version $PDF::Create::VERSION");

    # Add another page
    my $page2 = $root->new_page;
    $page2->line(0, 0, 612, 792);
    $page2->line(0, 792, 612, 0);

    $toc->new_outline('Title' => 'Section 3');
    $pdf->new_outline('Title' => 'Summary');

    # Add something to the first page
    $page->stringc($f1, 20, 306, 300,
                   'by Fabien Tassin <fta@oleane.net>');

    # Add the missing PDF objects and a the footer then close the file
    $pdf->close;
};
