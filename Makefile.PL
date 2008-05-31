# -*- mode: Perl -*-

use ExtUtils::MakeMaker;

WriteMakefile(NAME          => "PDF::Create",
              VERSION_FROM  => "lib/PDF/Create.pm",
	      ABSTRACT_FROM => "lib/PDF/Create.pm",
              dist          => { COMPRESS => "gzip", SUFFIX => "gz" },
              clean         => { FILES => '*.bak *.old mibs/*.dump *.pdf' .
                                          'lib/*/*~ lib/*/*/*~' },
);
