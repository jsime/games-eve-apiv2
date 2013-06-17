package Games::EVE::APIv2::Character;

use strict;
use warnings FATAL => 'all';
use namespace::autoclean;

use Moose;

extends 'Games::EVE::APIv2';

no Moose;
__PACKAGE__->meta->make_immutable;

1;
