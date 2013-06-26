package Games::EVE::APIv2::Base;

=head1 NAME

Games::EVE::APIv2::Base

=head1 SYNOPSIS

Base class for interfaces to various CCP API methods.

=cut

use strict;
use warnings FATAL => 'all';

use Games::EVE::APIv2::Request;

use Moose;
use MooseX::SetOnce;
use namespace::autoclean;

has 'key_id' => (
    is  => 'ro',
    isa => 'Num',
);

has 'v_code' => (
    is  => 'ro',
    isa => 'Str',
);

has 'access_mask' => (
    is     => 'rw',
    isa    => 'Int',
    traits => [qw( SetOnce )],
);

has 'key_type' => (
    is     => 'rw',
    isa    => 'Str',
    traits => [qw( SetOnce )],
);

has 'expires' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_expiration',
);

has 'req' => (
    is  => 'rw',
    isa => 'Games::EVE::APIv2::Request',
);

has 'cached_until' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'is_cached',
);

has 'character_list' => (
    is        => 'rw',
    isa       => 'ArrayRef[Games::EVE::APIv2::Character]',
    clearer   => 'clear_characters',
    predicate => 'has_characters',
);

has 'corporation_list' => (
    is        => 'rw',
    isa       => 'ArrayRef[Games::EVE::APIv2::Corporation]',
    clearer   => 'clear_corporations',
    predicate => 'has_corporations',
);

=head1 EXPORT

This library exports nothing but its constructor.

=head1 SUBROUTINES/METHODS

=head2 characters

Returns a list of Games::EVE::APIv2::Character objects for characters accessible
via the provided API Key.

=cut

sub characters {
    my ($self) = @_;

    return @{$self->character_list} if $self->has_characters;

    my @chars;

    my $xml = $self->req->get('account/Characters');

    foreach my $char_id ($xml->find(q{//result/rowset[@name='characters']/row/@characterID})) {
        push(@chars, Games::EVE::APIv2::Character->new(
                character_id => "$char_id",
                key_id       => $self->key_id,
                v_code       => $self->v_code
        ));
    }

    $self->character_list(\@chars);
    return @chars;
}

=head2 corporations

Returns list of Games::EVE::APIv2::Corporation objects for corporations accessible
via the provided API Key. Note that only CEOs and Directors may create corporate
API Keys.

Note also that this is not the same as calling the corporations() method through a
Character object - as that will return the character's corporate history instead.

=cut

sub corporations {
    my ($self) = @_;

    return @{$self->corporation_list} if $self->has_corporations;
}

=head1 INTERNAL SUBROUTINES

The following methods and subroutines are not intended for use by applications,
but are documented here for anyone hoping to chip away at the internal workings
of this library.

=head2 keyinfo

Returns a hash of key information, intended only for internal use to prevent
unnecessary remote API calls.

=cut

sub keyinfo {
    my ($self) = @_;

    my %info;

    $info{'access_mask'} = $self->access_mask if $self->has_access_mask;
    $info{'key_type'} = $self->key_type       if $self->has_key_type;
    $info{'expires'} = $self->expires         if $self->has_expiration;

    return %info;
}

=head2 BUILD

Constructor hook. Instantiates a ::Request object with provided API keys.

=cut

sub BUILD {
    my ($self) = @_;

    $self->req(Games::EVE::APIv2::Request->new( key_id => $self->key_id, v_code => $self->v_code));

    my $xml = $self->req->get('account/APIKeyInfo');

    $self->access_mask($xml->findvalue(q{//result/key/@accessMask}));
    $self->key_type(   $xml->findvalue(q{//result/key/@type}));

    my $expiration;
    if ($expiration = $xml->findvalue(q{//result/key/@expires})) {
        $self->expires($expiration);
    }
}

__PACKAGE__->meta->make_immutable;

1;
