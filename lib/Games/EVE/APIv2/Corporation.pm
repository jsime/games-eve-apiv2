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

has [qw( name ticker )] => (
    is     => 'rw',
    isa    => 'Str',
    traits => [qw( SetOnce )],
);

has [qw( url )] => (
    is     => 'rw',
    isa    => 'Maybe[Str]',
    traits => [qw( SetOnce )],
);

has [qw( tax_rate )] => (
    is     => 'rw',
    isa    => 'Maybe[Num]',
    traits => [qw( SetOnce )],
);

has [qw( shares member_count member_limit )] => (
    is     => 'rw',
    isa    => 'Maybe[Int]',
    traits => [qw( SetOnce )],
);

has 'alliance' => (
    is        => 'rw',
    isa       => 'Games::EVE::APIv2::Alliance',
    traits    => [qw( SetOnce )],
    predicate => 'has_alliance',
);

sub BUILD {
    my ($self) = @_;

    my $xml = $self->req->get('corp/CorporationSheet', corporationID => $self->corporation_id);

    $self->name(     $xml->findvalue(q{//result/corporationName[1]}));
    $self->ticker(   $xml->findvalue(q{//result/ticker[1]}));
    $self->url(      $xml->findvalue(q{//result/url[1]}));
    $self->tax_rate( $xml->findvalue(q{//result/taxRate[1]}));
    $self->shares(   $xml->findvalue(q{//result/shares[1]}));

    $self->member_count($xml->findvalue(q{//result/memberCount[1]}));
    $self->member_limit($xml->findvalue(q{//result/memberLimit[1]}) || undef);

    $self->alliance(Games::EVE::APIv2::Alliance->new(
        $self->keyinfo,
        alliance_id => $xml->findvalue(q{//result/allianceID[1]}),
    ));
}

__PACKAGE__->meta->make_immutable;

1;
