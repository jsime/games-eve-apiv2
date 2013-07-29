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
use MooseX::ClassAttribute;
use namespace::autoclean;

extends 'Games::EVE::APIv2::Base';

=head1 ATTRIBUTE METHODS

The following attribute methods are provided (or overridden) by this class, in
addition to those provided by the base class.

=cut

class_has 'Cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

=head2 character_id

The CCP-supplied Character ID represented by the object.

=cut

has 'character_id' => (
    is        => 'ro',
    isa       => 'Num',
    predicate => 'has_character_id',
    required  => 1,
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

has 'name' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_name',
);

has 'race' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_race',
);

has 'bloodline' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_bloodline',
);

has 'ancestry' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_ancestry',
);

has 'gender' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_gender',
);

has 'clone_name' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_clone_name',
);

has 'certificates_list' => (
    is        => 'rw',
    isa       => 'ArrayRef[Games::EVE::APIv2::Certificate]',
    traits    => [qw( SetOnce )],
    predicate => 'has_certificates_list',
);

=head2 dob

DateTime object representing the date of birth for the character.

=cut

has [qw( dob )] => (
    is        => 'rw',
    isa       => 'DateTime',
    traits    => [qw( SetOnce )],
    predicate => 'has_dob',
);

=head2 security_status

The current security status of the character.

=cut

has 'security_status' => (
    is        => 'rw',
    isa       => 'Num',
    traits    => [qw( SetOnce )],
    predicate => 'has_security_status',
);

=head2 balance

Decimal value of the character's current ISK balance.

=head2 clone_skillpoints

The total number of skill points supported by the character's current medical clone.

=cut

has 'balance' => (
    is        => 'rw',
    isa       => 'Num',
    traits    => [qw( SetOnce )],
    predicate => 'has_balance',
);

has 'clone_skillpoints' => (
    is        => 'rw',
    isa       => 'Num',
    traits    => [qw( SetOnce )],
    predicate => 'has_clone_skillpoints',
);

has 'skill_list' => (
    is        => 'rw',
    isa       => 'ArrayRef[Games::EVE::APIv2::Skill]',
    traits    => [qw( SetOnce )],
    predicate => 'has_skill_list',
);

has 'skill_queue_list' => (
    is        => 'rw',
    isa       => 'ArrayRef[Games::EVE::APIv2::Skill]',
    traits    => [qw( SetOnce )],
    predicate => 'has_skill_queue_list',
);

foreach my $attr (qw( name race bloodline ancestry gender clone_name clone_skillpoints dob security_status )) {
    before $attr => sub { my ($self, $value) = @_; $self->check_cache($attr, $value); }
}

=head1 INTERNAL METHODS

The following methods are for internal use only and should not be called by
applications using this library.

=cut

=head2 check_cache

Verifies attribute is already available in the object, otherwise makes the remote
API call to populate the cache and fills in the object.

=cut

sub check_cache {
    my ($self, $attr, $value) = @_;

    # Short-circuit if we're setting the value.
    return if defined $value;

    # Short-circuit if the Character ID is within the range of NPCs (encountered most
    # frequently as CEOs of NPC corps. Unfortunately, the CharacterInfo API returns a
    # 400 Bad Request for NPCs, instead of a dummied-up response.
    return if $self->character_id < 4_000_000;

    my $has_attr;

    if (defined $attr) {
        $has_attr = 'has_' . $attr;
        return 1 if $self->$has_attr;

        if (exists $self->Cache->{$self->character_id} && exists $self->Cache->{$self->character_id}{$attr}) {
            $self->$attr($self->Cache->{$self->character_id}{$attr});
            return 1;
        }
    }

    my $cached = {};

    my $xml = $self->req->get('eve/CharacterInfo', characterID => $self->character_id);
    my @nodes = $xml->findnodes(q{//result/rowset[@name='employmentHistory']/row});

    unless ($self->has_corporation_list) {
        my @corps;
        foreach my $corpnode (@nodes) {
            push(@corps, {
                corporation_id => $corpnode->findvalue(q{@corporationID}),
                start_date     => $self->parse_datetime($corpnode->findvalue(q{@startDate}))->add( seconds => 1 ),
            });
        }

        # Ensure that corporation memberships are sorted by the start_date so that
        # we can easily calculate the end_date (which CCP does not provide).
        @corps = sort { $b->{'start_date'} <=> $a->{'start_date'} } @corps;

        for (my $i = 0; $i < @corps; $i++) {
            if ($i > 0) {
                $corps[$i]{'end_date'} = $corps[$i-1]->start_date->subtract( seconds => 1 );
            }

            $corps[$i] = Games::EVE::APIv2::Corporation->new(
                key => $self->key,
                %{$corps[$i]}
            );
        }

        $self->corporation_list(\@corps);
    }

    $self->name(     $xml->findvalue(q{//result/characterName[1]}))        unless $self->has_name;
    $self->race(     $xml->findvalue(q{//result/race[1]}))                 unless $self->has_race;
    $self->bloodline($xml->findvalue(q{//result/bloodline[1]}))            unless $self->has_bloodline;
    $self->security_status($xml->findvalue(q{//result/securityStatus[1]})) unless $self->has_security_status;

    foreach $attr (qw( name race bloodline security_status corporation_list )) {
        $has_attr = 'has_' . $attr;
        $cached->{$attr} = $self->$attr if $self->$has_attr;
    }

    # Make sure the current key is for this character before trying to get more details.
    if ($self->key->for_character($self->character_id)) {
        $xml = $self->req->get('char/CharacterSheet', characterID => $self->character_id);

        $self->ancestry( $xml->findvalue(q{//result/ancestry[1]})) unless $self->has_ancestry;
        $self->gender(   $xml->findvalue(q{//result/gender[1]}))   unless $self->has_gender;
        $self->balance(  $xml->findvalue(q{//result/balance[1]}))  unless $self->has_balance;

        $self->clone_name(       $xml->findvalue(q{//result/cloneName[1]}))        unless $self->has_clone_name;
        $self->clone_skillpoints($xml->findvalue(q{//result/cloneSkillPoints[1]})) unless $self->has_clone_skillpoints;

        unless ($self->has_dob) {
            my $dob = $self->parse_datetime($xml->findvalue(q{//result/DoB[1]}));
            $self->dob($dob) if $dob;
        }

        unless ($self->has_skill_list) {
            my @skills;
            my @skillnodes = $xml->findnodes(q{//result/rowset[@name='skills']/row});
            foreach my $skillnode (@skillnodes) {
                push(@skills, Games::EVE::APIv2::Skill->new(
                    key         => $self->key,
                    skill_id    => $skillnode->findvalue(q{@typeID}),
                    level       => $skillnode->findvalue(q{@level}),
                    skillpoints_trained => $skillnode->findvalue(q{@skillpoints}),
                ));
            }
            $self->skill_list(\@skills) if @skills > 0;
        }

        unless ($self->has_certificates_list) {
            my @certificates;
            push(@certificates, Games::EVE::APIv2::Certificate->new(
                    key            => $self->key,
                    certificate_id => $_->findvalue(q{@certificateID}),
                )) for $xml->findnodes(q{//result/rowset[@name='certificates']/row});
            $self->certificates_list(\@certificates) if @certificates > 0;
        }

        $self->cached_until($self->parse_datetime($xml->findvalue(q{//cachedUntil[1]})))
            unless $self->has_cached_until;
    } else {
        $self->cached_until($self->parse_datetime($xml->findvalue(q{//cachedUntil[1]})));
    }

    foreach $attr (qw( ancestry gender balance clone_name clone_skillpoints dob skill_list certificates_list cached_until )) {
        $has_attr = 'has_' . $attr;
        $cached->{$attr} = $self->$attr if $self->$has_attr;
    }

    $self->Cache->{$self->character_id} = $cached;
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

    return @{$self->corporation_list} if $self->has_corporation_list;

    my $xml = $self->req->get('eve/CharacterInfo', characterID => $self->character_id);
    my @nodes = $xml->findnodes(q{//result/rowset[@name='employmentHistory']/row});

    my @corps;
    foreach my $corpnode (@nodes) {
        push(@corps, {
            corporation_id => $corpnode->findvalue(q{@corporationID}),
            start_date     => $self->parse_datetime($corpnode->findvalue(q{@startDate})),
        });
    }

    # Ensure that corporation memberships are sorted by the start_date so that
    # we can easily calculate the end_date (which CCP does not provide).
    @corps = sort { $b->{'start_date'} <=> $a->{'start_date'} } @corps;

    for (my $i = 0; $i < @corps; $i++) {
        if ($i > 0) {
            $corps[$i]{'end_date'} = $corps[$i-1]->start_date->subtract( seconds => 1 );
        }

        $corps[$i] = Games::EVE::APIv2::Corporation->new(
            key => $self->key,
            %{$corps[$i]}
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

    return @{$self->certificates_list} if $self->has_certificates_list;
    return;
}

=head2 skill_queue

=cut

sub skill_queue {
    my ($self) = @_;

    return @{$self->skill_queue_list} if $self->has_skill_queue_list;

    my $xml = $self->req->get('char/SkillQueue', characterID => $self->character_id);

    my @queue;
    foreach my $skillnode ($xml->findnodes(q{//result/rowset[@name='skillqueue']/row})) {
        push(@queue, Games::EVE::APIv2::Skill->new(
            key        => $self->key,
            skill_id   => $skillnode->findvalue(q{@typeID}),
            position   => $skillnode->findvalue(q{@queuePosition}),
            level      => $skillnode->findvalue(q{@level}),
        ));

        # if the queue is paused, skills will have null startTime and endTime attributes,
        # so we can't blindly pass them into the Skill object.
        my $start_time = $skillnode->findvalue(q{@startTime});
        $queue[-1]{'start_time'} = $self->parse_datetime($start_time) if $start_time;

        my $end_time = $skillnode->findvalue(q{@endTime});
        $queue[-1]{'end_time'} = $self->parse_datetime($end_time) if $end_time;
    }

    $self->skill_queue_list(\@queue);
    return @queue;
}

__PACKAGE__->meta->make_immutable;

1;
