package Games::EVE::APIv2::Key;

=head1 NAME

Games::EVE::APIv2::Key

=head1 SYNOPSIS

This class provides basic API Key validation, as well as convenience
methods to determine which characters' and corporations' extended details
may be accessed with a given key.

=cut

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::ClassAttribute;
use MooseX::SetOnce;
use namespace::autoclean;

use Games::EVE::APIv2::Request;

=head1 ATTRIBUTE METHODS

The following attribute methods are provided (or overridden) by this class, in
addition to those provided by the base class.

=cut

class_has 'Cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

=head2 key_id

The Key ID provided by the CCP website.

=cut

has 'key_id' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    required  => 1,
);

=head2 v_code

The Verification Code provided by the CCP website.

=cut

has 'v_code' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    required  => 1,
);

=head2 type

A string representing the type of the key. Valid strings are:
C<Account>, C<Character>, and C<Corporation>. Corporation keys may
only be created by CEOs and Directors.

=cut

has 'type' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_type',
);

=head2 mask

The Access Mask for the key, a bit mask enumerating the API endpoints
accessible with this key. There is only one mask attribute, and the
particular meaning of each bit will differ whether the key was for a
corporation or not.

=cut

has 'mask' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_mask',
);

=head2 expires

A DateTime object which contains the expiration date and time for the
key. If the key has no expiration, this will still be a DateTime
object, but it will be a DateTime::Infinite::Future instance, allowing
you to perform all normal DateTime comparisons, as well as call the
C<is_infinite> method and receive an intelligent (and appropriate)
response.

=cut

has 'expires' => (
    is        => 'rw',
    isa       => 'DateTime',
    traits    => [qw( SetOnce )],
    predicate => 'has_expires',
);

=head2 characters

An internally-oriented attribute, holding an array reference of
Character ID bigints for which this key is valid. It is recommended
that you not use this attribute directly, but instead call the
C<for_character> method described below. But I'm not the boss of you.

=cut

has 'characters' => (
    is        => 'rw',
    isa       => 'ArrayRef[Num]',
    traits    => [qw( SetOnce )],
    predicate => 'has_characters',
);

=head2 corporations

Same as C<characters>, except for corporation IDs.

=cut

has 'corporations' => (
    is        => 'rw',
    isa       => 'ArrayRef[Num]',
    traits    => [qw( SetOnce )],
    predicate => 'has_corporations',
);

=head1 INTERNAL METHODS

The following methods are for internal use only and should not be called by
applications using this library.

=cut

sub BUILD {
    my ($self) = @_;

    # Check for the key in the class cache, just in case something has caused us
    # to create two separate objects for the same key. (The goal is to be as nice
    # to CCP's API as we can be.)
    my $cache_key = $self->key_id . '/' . $self->v_code;
    my $cached;

    if (exists $self->Cache->{$cache_key}) {
        $cached = $self->Cache->{$cache_key};

        foreach my $k (qw( type mask expires characters corporations )) {
            $self->$k($cached->{$k});
        }

        return 1;
    }

    my $xml = Games::EVE::APIv2::Request->new->get(
        'account/APIKeyInfo',
        key_id => $self->key_id,
        v_code => $self->v_code
    );

    die "Invalid key" unless defined $xml;

    $cached = {
        type => $xml->findvalue(q{//result/key/@type}),
        mask => $xml->findvalue(q{//result/key/@accessMask}),
        expires      => DateTime::Infinite::Future->new,
        characters   => [],
        corporations => [],
    };

    if (my $expire = $xml->findvalue(q{//result/key/@expires})) {
        my $parser = DateTime::Format::Strptime->new( time_zone => 'UTC', pattern => '%F %T' );
        my $dt = $parser->parse_datetime($expire);
        $cached->{'expires'} = $dt if defined $dt;
    }

    foreach my $charnode ($xml->findnodes(q{//rowset[@name='characters']/row})) {
        my $char_id = $charnode->findvalue(q{@characterID});
        my $corp_id = $charnode->findvalue(q{@corporationID});

        push(@{$cached->{'characters'}}, $char_id);
        push(@{$cached->{'corporations'}}, $corp_id) if $cached->{'type'} eq 'Corporation';
    }

    $self->Cache->{$cache_key} = $cached;

    foreach my $k (qw( type mask expires characters corporations )) {
        $self->$k($cached->{$k});
    }

    return 1;
}

=head2 for_character

Given a Character ID, will return true or false for whether this key is
valid for that character.

=cut

sub for_character {
    my ($self, $character_id) = @_;

    return unless $self->has_characters;
    return 1 if grep { $_ == $character_id } @{$self->characters};
    return 0;
}

=head2 for_corporation

Given a Corporation ID, will return true or false for whether this key is
valid for that corporation.

=cut

sub for_corporation {
    my ($self, $corporation_id) = @_;

    return unless $self->has_corporations;
    return 1 if grep { $_ == $corporation_id } @{$self->corporations};
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;
