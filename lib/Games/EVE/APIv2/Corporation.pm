package Games::EVE::APIv2::Corporation;

=head1 NAME

Games::EVE::APIv2::Corporation

=head1 SYNOPSIS

Subclass providing access to corporation information.

=cut

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::ClassAttribute;
use namespace::autoclean;

extends 'Games::EVE::APIv2::Base';

class_has 'Cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'corporation_id' => (
    is        => 'ro',
    isa       => 'Num',
    predicate => 'has_corporation_id',
    required  => 1,
);

has 'name' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_name',
);

has 'ticker' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_ticker',
);

has 'url' => (
    is        => 'rw',
    isa       => 'Maybe[Str]',
    traits    => [qw( SetOnce )],
    predicate => 'has_url',
);

has 'tax_rate' => (
    is        => 'rw',
    isa       => 'Maybe[Num]',
    traits    => [qw( SetOnce )],
    predicate => 'has_tax_rate',
);

has 'shares' => (
    is        => 'rw',
    isa       => 'Maybe[Int]',
    traits    => [qw( SetOnce )],
    predicate => 'has_shares',
);

has 'member_count' => (
    is        => 'rw',
    isa       => 'Maybe[Int]',
    traits    => [qw( SetOnce )],
    predicate => 'has_member_count',
);

has 'alliance' => (
    is        => 'rw',
    isa       => 'Games::EVE::APIv2::Alliance',
    traits    => [qw( SetOnce )],
    predicate => 'has_alliance',
);

has 'ceo' => (
    is        => 'rw',
    isa       => 'Games::EVE::APIv2::Character',
    traits    => [qw( SetOnce )],
    predicate => 'has_ceo',
);

foreach my $attr (qw( name ticker url tax_rate shares member_count alliance ceo )) {
    before $attr => sub { my ($self, $value) = @_; $self->check_cache($attr, $value); }
}

sub check_cache {
    my ($self, $attr, $value) = @_;

    # Short-circuit if we're setting the value.
    return if defined $value;

    my $has_attr;

    if (defined $attr) {
        $has_attr = 'has_' . $attr;
        return 1 if $self->$has_attr;

        if (exists $self->Cache->{$self->corporation_id} && exists $self->Cache->{$self->corporation_id}{$attr}) {
            $self->$attr($self->Cache->{$self->corporation_id}{$attr});
            return 1;
        }
    }

    my $cached = {};

    my $xml = $self->req->get('corp/CorporationSheet', corporationID => $self->corporation_id);

    $self->name(     $xml->findvalue(q{//result/corporationName[1]})) unless $self->has_name;
    $self->ticker(   $xml->findvalue(q{//result/ticker[1]}))          unless $self->has_ticker;
    $self->url(      $xml->findvalue(q{//result/url[1]}))             unless $self->has_url;
    $self->tax_rate( $xml->findvalue(q{//result/taxRate[1]}))         unless $self->has_tax_rate;
    $self->shares(   $xml->findvalue(q{//result/shares[1]}))          unless $self->has_shares;

    $self->member_count($xml->findvalue(q{//result/memberCount[1]})) unless $self->has_member_count;

    $self->ceo(Games::EVE::APIv2::Character->new(
        key          => $self->key,
        character_id => $xml->findvalue(q{//result/ceoID[1]}),
        name         => $xml->findvalue(q{//result/ceoName[1]}),
    )) unless $self->has_ceo;

    $self->alliance(Games::EVE::APIv2::Alliance->new(
        key         => $self->key,
        alliance_id => $xml->findvalue(q{//result/allianceID[1]}),
        name        => $xml->findvalue(q{//result/allianceName[1]}),
    )) unless $self->has_alliance;

    foreach $attr (qw( name ticker url tax_rate shares member_count ceo alliance )) {
        $has_attr = 'has_' . $attr;
        $cached->{$attr} = $self->$attr if $self->$has_attr;
    }

    $self->Cache->{$self->corporation_id} = $cached;
}

__PACKAGE__->meta->make_immutable;

1;
