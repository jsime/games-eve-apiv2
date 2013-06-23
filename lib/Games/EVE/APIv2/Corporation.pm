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

has [qw( name ticker url )] => (
    is     => 'rw',
    isa    => 'Str',
    traits => [qw( SetOnce )],
);

has [qw( tax_rate )] => (
    is     => 'rw',
    isa    => 'Num',
    traits => [qw( SetOnce )],
);

has [qw( shares member_count member_limit )] => (
    is     => 'rw',
    isa    => 'Int',
    traits => [qw( SetOnce )],
);

sub BUILD {
    my ($self) = @_;

    my $xml = $self->req->get('char/CorporationSheet', corporationID => $self->corporation_id);

    $self->name(     $xml->findvalue(q{//result/corporationName[1]}));
    $self->ticker(   $xml->findvalue(q{//result/ticker[1]}));
    $self->url(      $xml->findvalue(q{//result/url[1]}));
    $self->tax_rate( $xml->findvalue(q{//result/taxRate[1]}));
    $self->shares(   $xml->findvalue(q{//result/shares[1]}));

    $self->member_count( $xml->findvalue(q{//result/memberCount[1]}));
    $self->member_limit( $xml->findvalue(q{//result/memberLimit[1]}));
}

__PACKAGE__->meta->make_immutable;

1;
