#
# Makefile.PL for PDF::Create
#
use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => "PDF::Create",
	VERSION_FROM  => "lib/PDF/Create.pm",
	ABSTRACT_FROM => "lib/PDF/Create.pm",
    'PREREQ_PM'   => {
               'Carp' => 0,
               'Filehandle' => 0,
               'Data::Dumper' => 0,
    },
	LICENSE       => "perl",
	dist          => { COMPRESS => "gzip", SUFFIX => "gz" },
	clean 		  => { FILES => '*.bak *.old mibs/*.dump *.pdf' . 'lib/*/*~ lib/*/*/*~' },
    META_MERGE => {
          resources => {
               repository => 'http://github.com/szabgab/pdf-create',
          }
    },
);
