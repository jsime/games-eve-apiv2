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

use Moose;
use namespace::autoclean;

extends 'Games::EVE::APIv2::Base';

has 'character_id' => (
    is        => 'ro',
    isa       => 'Num',
    predicate => 'has_character_id',
);

has 'name' => (
    is  => 'rw',
    isa => 'Str',
    traits => [qw( SetOnce )],
);

sub BUILD {
    my ($self) = @_;

    my $xml = $self->req->get('char/CharacterSheet', characterID => $self->character_id);

    $self->name($xml->findvalue(q{//result/name[1]}));
}

__PACKAGE__->meta->make_immutable;

1;
