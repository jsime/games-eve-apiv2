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

=head1 ATTRIBUTE METHODS

The following attribute methods are provided (or overridden) by this class, in
addition to those provided by the base class.

=cut

=head2 character_id

The CCP-supplied Character ID represented by the object.

=cut

has 'character_id' => (
    is        => 'ro',
    isa       => 'Num',
    predicate => 'has_character_id',
);

=head2 name

The character's name.

=head2 race

The character's race.

=head2 bloodline

The character's bloodline.

=head2 ancestry

The character's ancestry.

=head2 gender

The character's gender.

=head2 clone_name

The name of the character's current medical clone grade.

=cut

has [qw( name race bloodline ancestry gender clone_name )] => (
    is     => 'rw',
    isa    => 'Str',
    traits => [qw( SetOnce )],
);

has 'certificates_list' => (
    is        => 'rw',
    isa       => 'ArrayRef[Games::EVE::APIv2::Certificate]',
    traits    => [qw( SetOnce )],
    predicate => 'has_certificate_list',
);

=head2 dob

DateTime object representing the date of birth for the character.

=cut

has [qw( dob )] => (
    is     => 'rw',
    isa    => 'DateTime',
    traits => [qw( SetOnce )],
);

=head2 balance

Decimal value of the character's current ISK balance.

=head2 clone_skillpoints

The total number of skill points supported by the character's current medical clone.

=cut

has [qw( balance clone_skillpoints )] => (
    is     => 'rw',
    isa    => 'Num',
    traits => [qw( SetOnce )],
);

has 'skill_list' => (
    is        => 'rw',
    isa       => 'ArrayRef[Games::EVE::APIv2::Skill]',
    traits    => [qw( SetOnce )],
    predicate => 'has_skill_list',
);

=head1 INTERNAL METHODS

The following methods are for internal use only and should not be called by
applications using this library.

=cut

sub BUILD {
    my ($self) = @_;

    my $xml = $self->req->get('char/CharacterSheet', characterID => $self->character_id);

    $self->name(     $xml->findvalue(q{//result/name[1]}));
    $self->race(     $xml->findvalue(q{//result/race[1]}));
    $self->bloodline($xml->findvalue(q{//result/bloodLine[1]}));
    $self->ancestry( $xml->findvalue(q{//result/ancestry[1]}));
    $self->gender(   $xml->findvalue(q{//result/gender[1]}));
    $self->balance(  $xml->findvalue(q{//result/balance[1]}));

    $self->clone_name(       $xml->findvalue(q{//result/cloneName[1]}));
    $self->clone_skillpoints($xml->findvalue(q{//result/cloneSkillPoints[1]}));

    my $dob = $self->parse_datetime($xml->findvalue(q{//result/DoB[1]}));
    $self->dob($dob) if $dob;

    my @skills;
    my @skillnodes = $xml->findnodes(q{//result/rowset[@name='skills']/row});
    foreach my $skillnode (@skillnodes) {
        push(@skills, Games::EVE::APIv2::Skill->new(
            $self->keyinfo,
            skill_id    => $skillnode->findvalue(q{@typeID}),
            level       => $skillnode->findvalue(q{@level}),
            skillpoints_trained => $skillnode->findvalue(q{@skillpoints}),
        ));
    }
    $self->skill_list(\@skills);

    my @certificates;
    push(@certificates, Games::EVE::APIv2::Certificate->new(
            $self->keyinfo,
            certificate_id => $_->findvalue(q{@certificateID}),
        )) for $xml->findnodes(q{//result/rowset[@name='certificates']/row});
    $self->certificates_list(\@certificates);

    $self->cached_until($self->parse_datetime($xml->findvalue(q{//cachedUntil[1]})));
}

=head1 METHODS

The following non-attribute methods are provided, or overridden, by this class.

=cut

=head2 corporations

Returns a list of Games::EVE::APIv2::Corporation objects representing the
employment history of the character. This overrides the C<corporations> method
from the base class.

Note that Corporation objects created via this method gain an additional
pair of attributes, C<start_date> and C<end_date>, which define the period of
employment for the character with that corporation.

Keep in mind that there may be duplication of corporations in this list, as a
single pilot may have joined, left, and rejoined a single corporation more than
once.

=cut

sub corporations {
    my ($self) = @_;

    return @{$self->corporation_list} if $self->has_corporations;

    my $xml = $self->req->get('eve/CharacterInfo', characterID => $self->character_id);
    my @nodes = $xml->findnodes(q{//result/rowset[@name='employmentHistory']/row});

    my @corps;
    foreach my $corpnode (@nodes) {
        push(@corps,
            Games::EVE::APIv2::Corporation->new(
                $self->keyinfo,
                corporation_id => $corpnode->findvalue(q{@corporationID}),
            )
        );
    }

    $self->corporation_list(\@corps);
    return @corps;
}

=head2 skills

Returns a list of Games::EVE::APIv2::Skill objects representing the skills trained
by the character.

As with the corporations method, objects created from here gain methods not normally
present when instantiating a Skill object directly. In this case, the methods are:
C<level> and C<skillpoints_trained>. These indicate the current level of training
finished by the character and the total number of skillpoints accumulated for the
given skill, respectively.

=cut

sub skills {
    my ($self) = @_;

    return @{$self->skill_list} if $self->has_skill_list;
    return;
}

=head2 certificates

Returns a list of Games::EVE::APIv2::Certificate objects representing the certificates
earned by the character.

=cut

sub certificates {
    my ($self) = @_;

    return @{$self->certificates_list} if $self->has_certificate_list;
    return;
}

__PACKAGE__->meta->make_immutable;

1;
