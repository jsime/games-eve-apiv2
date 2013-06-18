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
    is  => 'ro',
    isa => 'Int',
);

has 'key_type' => (
    is  => 'ro',
    isa => 'Str',
);

has 'expires' => (
    is  => 'ro',
    isa => 'DateTime',
);

has 'req' => (
    is  => 'rw',
    isa => 'Games::EVE::APIv2::Request',
);

has 'character_list' => (
    is        => 'rw',
    isa       => 'ArrayRef[Games::EVE::APIv2::Character]',
    clearer   => 'clear_characters',
    predicate => 'has_characters',
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

=head1 INTERNAL SUBROUTINES

The following methods and subroutines are not intended for use by applications,
but are documented here for anyone hoping to chip away at the internal workings
of this library.

=head2 BUILD

Constructor hook. Instantiates a ::Request object with provided API keys.

=cut

sub BUILD {
    my ($self) = @_;

    $self->req(Games::EVE::APIv2::Request->new( key_id => $self->key_id, v_code => $self->v_code));
}

__PACKAGE__->meta->make_immutable;

1;
