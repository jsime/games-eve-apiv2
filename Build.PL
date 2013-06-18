use v5.16;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Games::EVE::APIv2',
    license             => 'perl',
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
        'LWP::UserAgent'    => 0,
        'Moose'             => 0,
        'MooseX::SetOnce'   => 0,
        'URI::Escape'       => 0,
        'XML::LibXML'       => 0,
    },
    add_to_cleanup     => [ 'Games-EVE-APIv2-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
