package Games::EVE::APIv2::Character;

=head1 NAME

Games::EVE::APIv2::Character

=head1 SYNOPSIS

Subclass providing access to individual pilot details. Calls to some of the
methods in the base C<Games::EVE::APIv2> class are modified in the context
of a Character object.

=cut

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

extends 'Games::EVE::APIv2::Base';

has 'character_id' => (
    is        => 'ro',
    isa       => 'Num',
    predicate => 'has_character_id',
);

has [qw( name race bloodline ancestry gender )] => (
    is     => 'rw',
    isa    => 'Str',
    traits => [qw( SetOnce )],
);

has 'certificates_list' => (
    is        => 'rw',
    isa       => 'ArrayRef[Int]',
    traits    => [qw( SetOnce )],
    predicate => 'has_certificate_list',
);

has [qw( dob )] => (
    is     => 'rw',
    isa    => 'DateTime',
    traits => [qw( SetOnce )],
);

has [qw( balance )] => (
    is     => 'rw',
    isa    => 'Num',
    traits => [qw( SetOnce )],
);

has 'skill_list' => (
    is        => 'rw',
    isa       => 'ArrayRef[HashRef]',
    traits    => [qw( SetOnce )],
    predicate => 'has_skill_list',
);

sub BUILD {
    my ($self) = @_;

    my $xml = $self->req->get('char/CharacterSheet', characterID => $self->character_id);

    $self->name(     $xml->findvalue(q{//result/name[1]}));
    $self->race(     $xml->findvalue(q{//result/race[1]}));
    $self->bloodline($xml->findvalue(q{//result/bloodLine[1]}));
    $self->ancestry( $xml->findvalue(q{//result/ancestry[1]}));
    $self->gender(   $xml->findvalue(q{//result/gender[1]}));
    $self->balance(  $xml->findvalue(q{//result/balance[1]}));

    my $dob = $self->parse_datetime($xml->findvalue(q{//result/DoB[1]}));
    $self->dob($dob) if $dob;

    my @skills;
    my @skillnodes = $xml->findnodes(q{//result/rowset[@name='skills']/row});
    foreach my $skillnode (@skillnodes) {
        push(@skills, {
            skill_id     => $skillnode->findvalue(q{@typeID}),
            level        => $skillnode->findvalue(q{@level}),
            skill_points => $skillnode->findvalue(q{@skillpoints}),
            published    => $skillnode->findvalue(q{@published}),
        });
    }
    $self->skill_list(\@skills);

    my @certificates;
    push(@certificates, $_->findvalue(q{@certificateID}))
        for $xml->findnodes(q{//result/rowset[@name='certificates']/row});
    $self->certificates_list(\@certificates);

    $self->cached_until($self->parse_datetime($xml->findvalue(q{//cachedUntil[1]})));
}

sub corporations {
    my ($self) = @_;

    return @{$self->corporation_list} if $self->has_corporations;

    my $xml = $self->req->get('eve/CharacterInfo', characterID => $self->character_id);
    my @nodes = $xml->findnodes(q{//result/rowset[@name='employmentHistory']/row});

    my @corps;
    foreach my $corpnode (@nodes) {
        push(@corps,
            Games::EVE::APIv2::Corporation->new(
                key_id => $self->key_id, v_code => $self->v_code,
                corporation_id => $corpnode->findvalue(q{@corporationID}),
            )
        );
    }

    $self->corporation_list(\@corps);
    return @corps;
}

sub skills {
    my ($self) = @_;

    return @{$self->skill_list} if $self->has_skill_list;
    return;
}

sub certificates {
    my ($self) = @_;

    return @{$self->certificates_list} if $self->has_certificate_list;
    return;
}

__PACKAGE__->meta->make_immutable;

1;
