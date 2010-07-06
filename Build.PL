#
# Build.PL for PDF::Create
#
use Module::Build;

my $build = Module::Build->new(
     module_name => 'PDF::Create',
     license  => 'perl',
     requires => {
                  'perl'          => '5.5.0',
                 },
    );
    
$build->create_build_script;
