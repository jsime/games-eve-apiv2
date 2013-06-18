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
    is     => 'rw',
    isa    => 'Str',
    traits => [qw( SetOnce )],
);

has 'dob' => (
    is     => 'rw',
    isa    => 'Str',
    traits => [qw( SetOnce )],
);

has 'race' => (
    is     => 'rw',
    isa    => 'Str',
    traits => [qw( SetOnce )],
);

has 'bloodline' => (
    is     => 'rw',
    isa    => 'Str',
    traits => [qw( SetOnce )],
);

has 'ancestry' => (
    is     => 'rw',
    isa    => 'Str',
    traits => [qw( SetOnce )],
);

has 'gender' => (
    is     => 'rw',
    isa    => 'Str',
    traits => [qw( SetOnce )],
);

has 'balance' => (
    is     => 'rw',
    isa    => 'Num',
    traits => [qw( SetOnce )],
);

sub BUILD {
    my ($self) = @_;

    my $xml = $self->req->get('char/CharacterSheet', characterID => $self->character_id);

    $self->name(     $xml->findvalue(q{//result/name[1]}));
    $self->dob(      $xml->findvalue(q{//result/DoB[1]}));
    $self->race(     $xml->findvalue(q{//result/race[1]}));
    $self->bloodline($xml->findvalue(q{//result/bloodLine[1]}));
    $self->ancestry( $xml->findvalue(q{//result/ancestry[1]}));
    $self->gender(   $xml->findvalue(q{//result/gender[1]}));
    $self->balance(  $xml->findvalue(q{//result/balance[1]}));
}

__PACKAGE__->meta->make_immutable;

1;
