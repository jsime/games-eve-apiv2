package Games::EVE::APIv2::Character;

=head1 NAME

Games::EVE::APIv2::Character

=head1 SYNOPSIS

Subclass providing access to individual pilot details. Calls to some of the
methods in the base C<Games::EVE::APIv2> class are modified in the context
of a Character object.

=cut

use strict;
use warnings FATAL => 'all';
use namespace::autoclean;

use Moose;

extends 'Games::EVE::APIv2';

has 'key_id' => (
    is  => 'ro',
    isa => 'Int',
);

has 'v_code' => (
    is  => 'ro',
    isa => 'Str',
);

has 'character_id' => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_character_id',
);

has 'name' => (
    is  => 'ro',
    isa => 'Str',
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
