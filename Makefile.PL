#
# Makefile.PL for PDF::Create
#

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => "PDF::Create",
	VERSION_FROM => "lib/PDF/Create.pm",

	#              VERSION       => "$version",
	ABSTRACT_FROM => "lib/PDF/Create.pm",
	LICENSE       => "perl",
	dist          => { COMPRESS => "gzip", SUFFIX => "gz" },
	clean => { FILES => '*.bak *.old mibs/*.dump *.pdf' . 'lib/*/*~ lib/*/*/*~' },
			 );
