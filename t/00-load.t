#!perl -T
use 5.016;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Games::EVE::APIv2' ) || print "Bail out!\n";
}

diag( "Testing Games::EVE::APIv2 $Games::EVE::APIv2::VERSION, Perl $], $^X" );
