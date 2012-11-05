use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    dynamic_config       => 0,

    build_requires       => {
        'Test::More' => '0.98',
        'Test::Requires' => 0,
    },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        perl => '5.008001',
        'parent'                        => '0',
        'Data::OptList' => 0,
        'Module::Load' => 0,
        'Class::Method::Modifiers' => 0,
        'Module::Build' => '0.38',
        'Class::Accessor::Lite' => 0,

        # Test::Module::Build::Pluggable
        'Test::SharedFork' => 0,
        'File::Temp' => 0,
        'File::Basename' => 0,
        'File::Path' => 0,
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => 'Module-Build-Pluggable',
    module_name => 'Module::Build::Pluggable',

    # script_files => [''],

    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,
   
    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
