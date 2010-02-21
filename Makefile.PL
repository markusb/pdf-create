#
# Makefile.PL for PDF::Create
#

use ExtUtils::MakeMaker;

#my $version = `git tag -l | tail -1`;
#chop $version;
#$version="1.05-rc1";
#my $abstract = "Create PDF with your perl script";

#printf "Creating makefile for PDF::Create v$version\n";

WriteMakefile(NAME          => "PDF::Create",
              VERSION_FROM  => "lib/PDF/Create.pm",
#              VERSION       => "$version",
	      ABSTRACT_FROM => "lib/PDF/Create.pm",
#	      ABSTRACT      => "$abstract",
              LICENSE       => "perl",
              dist          => { COMPRESS => "gzip", SUFFIX => "gz" },
              clean         => { FILES => '*.bak *.old mibs/*.dump *.pdf' .
                                          'lib/*/*~ lib/*/*/*~' },
);
