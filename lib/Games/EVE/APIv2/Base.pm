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

has 'key' => (
    is       => 'ro',
    isa      => 'Games::EVE::APIv2::Key',
    required => 1
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
    predicate => 'has_character_list',
);

has 'corporation_list' => (
    is        => 'rw',
    isa       => 'ArrayRef[Games::EVE::APIv2::Corporation]',
    clearer   => 'clear_corporations',
    predicate => 'has_corporation_list',
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

    return @{$self->character_list} if $self->has_character_list;

    my @chars;

    my $xml = $self->req->get('account/Characters');

    foreach my $char ($xml->findnodes(q{//result/rowset[@name='characters']/row})) {
        my $char_id = $char->findvalue(q{@characterID});

        push(@chars, Games::EVE::APIv2::Character->new(
                key          => $self->key,
                character_id => $char_id,
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

    return @{$self->corporation_list} if $self->has_corporation_list;
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

    $self->req(Games::EVE::APIv2::Request->new( key => $self->key ));
}

__PACKAGE__->meta->make_immutable;

1;
