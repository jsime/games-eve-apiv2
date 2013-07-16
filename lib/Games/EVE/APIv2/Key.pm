package Games::EVE::APIv2::Key;

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::ClassAttribute;
use MooseX::SetOnce;
use namespace::autoclean;

use Games::EVE::APIv2::Request;

class_has 'Cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => {},
);

has 'key_id' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    required  => 1,
);

has 'v_code' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    required  => 1,
);

has 'type' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_type',
);

has 'mask' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_mask',
);

has 'expires' => (
    is        => 'rw',
    isa       => 'DateTime',
    traits    => [qw( SetOnce )],
    predicate => 'has_expires',
);

has 'characters' => (
    is        => 'rw',
    isa       => 'ArrayRef[Num]',
    traits    => [qw( SetOnce )],
    predicate => 'has_characters',
);

has 'corporations' => (
    is        => 'rw',
    isa       => 'ArrayRef[Num]',
    traits    => [qw( SetOnce )],
    predicate => 'has_corporations',
);

sub BUILD {
    my ($self) = @_;

    # Check for the key in the class cache, just in case something has caused us
    # to create two separate objects for the same key. (The goal is to be as nice
    # to CCP's API as we can be.)
    $cache_key = $self->key_id . '/' . $self->v_code;
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

sub for_character {
    my ($self, $character_id) = @_;
}

sub for_corporation {
    my ($self, $corporation_id) = @_;
}

__PACKAGE__->meta->make_immutable;

1;
