package Games::EVE::APIv2::Corporation;

=head1 NAME

Games::EVE::APIv2::Corporation

=head1 SYNOPSIS

Subclass providing access to corporation information.

=cut

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

extends 'Games::EVE::APIv2::Base';

has 'corporation_id' => (
    is        => 'ro',
    isa       => 'Num',
    predicate => 'has_corporation_id',
);

has 'name' => (
    is     => 'rw',
    isa    => 'Str',
    traits => [qw( SetOnce )],
);

has 'ticker' => (
    is     => 'rw',
    isa    => 'Str',
    traits => [qw( SetOnce )],
);

has 'url' => (
    is     => 'rw',
    isa    => 'Str',
    traits => [qw( SetOnce )],
);

has 'tax_rate' => (
    is     => 'rw',
    isa    => 'Num',
    traits => [qw( SetOnce )],
);

sub BUILD {
    my ($self) = @_;

    my $xml = $self->req->get('char/CorporationSheet', corporationID => $self->corporation_id);

    $self->name(     $xml->findvalue(q{//result/corporationName[1]}));
}

__PACKAGE__->meta->make_immutable;

1;
