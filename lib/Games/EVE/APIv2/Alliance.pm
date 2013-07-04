package Games::EVE::APIv2::Alliance;

=head1 NAME

Games::EVE::APIv2::Alliance

=head1 SYNOPSIS

Subclass providing access to EVE Online's alliance list.

=cut

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::ClassAttribute;
use namespace::autoclean;

extends 'Games::EVE::APIv2::Base';

class_has 'Cache' => (
    is        => 'rw',
    isa       => 'HashRef[HashRef]',
    predicate => 'is_cached'
);

has 'alliance_id' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_alliance_id',
);

has 'name' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_name',
);

has 'short_name' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_short_name',
);

has 'executor' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_executor',
);

has 'founded' => (
    is        => 'rw',
    isa       => 'DateTime',
    traits    => [qw( SetOnce )],
    predicate => 'has_founded',
);

has 'check_called' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

foreach my $attr (qw( alliance_id name short_name executor founded )) {
    before $attr => sub { $_[0]->check_called || $_[0]->check_cache($attr) }
}

sub check_cache {
    my ($self, $attr) = @_;

    my $has_attr = 'has_' . $attr;

    return if $self->is_cached || $self->$has_attr;
    $self->update_cache;
    $self->check_called(1);

    my $alliance;
    if ($self->has_alliance_id && exists $self->Cache->{$self->alliance_id}) {
        $alliance = $self->Cache->{$self->alliance_id};
    } elsif ($self->has_name) {
        my $alliance_id = (grep { lc($self->Cache->{$_}{'name'}) eq lc($self->name) }
                            keys %{$self->Cache})[0];
        $alliance = $self->Cache->{$alliance_id}
            if defined $alliance_id && exists $self->Cache->{$alliance_id};
    } elsif ($self->has_short_name) {
        my $alliance_id = (grep { lc($self->Cache->{$_}{'short_name'}) eq lc($self->short_name) }
                            keys %{$self->Cache})[0];
        $alliance = $self->Cache->{$alliance_id}
            if defined $alliance_id && exists $self->Cache->{$alliance_id};
    }

    return unless defined $alliance;

    $self->alliance_id($alliance->{'alliance_id'}) unless $self->has_alliance_id;
    $self->name($alliance->{'name'}) unless $self->has_name;
    $self->short_name($alliance->{'short_name'}) unless $self->has_short_name;
    $self->founded($self->parse_datetime($alliance->{'founded'})) unless $self->has_founded;
    $self->executor(
        Games::EVE::APIv2::Corporation->new(
            key_id => $self->key_id,
            v_code => $self->v_code,
            corporation_id => $alliance->{'executor'},
        )) unless $self->has_executor;
}

sub update_cache {
    my ($self) = @_;

    return if $self->is_cached;

    my $xml = $self->req->get('eve/AllianceList');

    my %alliances;

    foreach my $alliancenode ($xml->findnodes(q{//rowset[@name='alliances']/row})) {
        my $alliance_id = $alliancenode->findvalue(q{@allianceID});

        $alliances{$alliance_id} = {
            alliance_id => $alliance_id,
            name        => $alliancenode->findvalue(q{@name}),
            short_name  => $alliancenode->findvalue(q{@shortName}),
            executor    => $alliancenode->findvalue(q{@executorCorpID}),
            founded     => $alliancenode->findvalue(q{@startDate}),
        }
    }

    $self->Cache(\%alliances);
}

__PACKAGE__->meta->make_immutable;

1;
