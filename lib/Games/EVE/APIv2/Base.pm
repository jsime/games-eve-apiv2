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

use DateTime;
use DateTime::Format::Strptime;
use DateTime::Infinite;

use namespace::autoclean;

has 'key_id' => (
    is        => 'ro',
    isa       => 'Num',
    predicate => 'has_key_id',
);

has 'v_code' => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_v_code',
);

has 'access_mask' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_access_mask',
);

has 'key_type' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_key_type',
);

has 'expires' => (
    is        => 'rw',
    isa       => 'DateTime',
    traits    => [qw( SetOnce )],
    predicate => 'has_expiration',
);

has 'req' => (
    is  => 'rw',
    isa => 'Games::EVE::APIv2::Request',
);

has 'cached_until' => (
    is        => 'rw',
    isa       => 'DateTime',
    traits    => [qw( SetOnce )],
    predicate => 'has_cached_until',
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
                $self->keyinfo,
                character_id => "$char_id",
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

=head2 is_cached

If the current API object has a cached_until attribute and the current time is
earlier than the value of that attribute, this method will return true. In all
other cases, including non-existence of the attribute, it will return false.

=cut

sub is_cached {
    my ($self) = @_;

    return 1 if $self->has_cached_until && $self->cached_until >= DateTime->now();
    return 0;
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

    $info{'key_id'} = $self->key_id           if $self->has_key_id;
    $info{'v_code'} = $self->v_code           if $self->has_v_code;
    $info{'access_mask'} = $self->access_mask if $self->has_access_mask;
    $info{'key_type'} = $self->key_type       if $self->has_key_type;
    $info{'expires'} = $self->expires         if $self->has_expiration;

    return %info;
}

=head2 parse_datetime

Thin convenience wrapper around datetime parser, since all EVE API calls use a
consistent datetime format, always in UTC, that's easily handled by strptime.

=cut

sub parse_datetime {
    my ($self, $datetime_str) = @_;

    return unless defined $datetime_str;

    my $parser = DateTime::Format::Strptime->new(
        time_zone => 'UTC',
        pattern => '%F %T'
    );

    my $dt = $parser->parse_datetime($datetime_str);

    return $dt if defined $dt;
    return;
}

=head2 BUILD

Constructor hook. Instantiates a ::Request object with provided API keys.

=cut

sub BUILD {
    my ($self) = @_;

    $self->req(Games::EVE::APIv2::Request->new( key_id => $self->key_id, v_code => $self->v_code));

    if ($self->has_key_id && $self->has_v_code) {
        unless ($self->has_access_mask && $self->has_key_type && $self->has_expiration) {
            my $xml = $self->req->get('account/APIKeyInfo');

            $self->access_mask($xml->findvalue(q{//result/key/@accessMask})) unless $self->has_access_mask;
            $self->key_type(   $xml->findvalue(q{//result/key/@type}))       unless $self->has_key_type;

            unless ($self->has_expiration) {
                my $expiration;
                if ($expiration = $xml->findvalue(q{//result/key/@expires})) {
                    $self->expires($self->parse_datetime($expiration));
                } else {
                    $self->expires(DateTime::Infinite::Future->new());
                }
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
