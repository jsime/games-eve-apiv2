use 5.016;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Games::EVE::APIv2',
    license             => 'Artistic_2_0',
    dist_author         => q{Jon Sime <jonsime@gmail.com>},
    dist_version_from   => 'lib/Games/EVE/APIv2.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    add_to_cleanup     => [ 'Games-EVE-APIv2-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
