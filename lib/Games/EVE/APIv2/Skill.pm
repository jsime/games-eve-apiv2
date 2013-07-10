package Games::EVE::APIv2::Skill;

=head1 NAME

Games::EVE::APIv2::Skill

=head1 SYNOPSIS

Subclass providing access to EVE Online's skill tree information. Will perform
a remote API call the first time any skill tree information is requested, and
will then cache that data as a class variable.

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
    is        => 'rw',
    isa       => 'HashRef[HashRef]',
    predicate => 'is_cached'
);

=head2 skill_id

The CCP-supplied Type ID for the skill.

=cut

has 'skill_id' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_skill_id',
);

=head2 name

The skill's name.

=cut

has 'name' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_name',
);

=head2 description

The skill's description.

=cut

has 'description' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_description',
);

=head2 rank

The skill's rank.

=cut

has 'rank' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_rank',
);

=head2 level

The trained level of the skill. Available only when Skill object was created through
a call to a Character's C<skills> method.

=cut

has 'level' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_level',
);

=head2 skillpoints_trained

The number of skillpoints accumulated in training for this skill. Available only
when Skill object created through a call to a Character's C<skills> method.

=cut

has 'skillpoints_trained' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_skillpoints_trained',
);

=head2 required_skills

Returns Skill objects representing the list of skill pre-requisites for this Skill.
Skill objects from this list will have the additional C<level> attribute, indicating
the minimum necessary level of the pre-requisite.

=cut

has 'required_skills' => (
    is        => 'rw',
    isa       => 'ArrayRef[Games::EVE::APIv2::Skill]',
    traits    => [qw( SetOnce )],
    predicate => 'has_required_skills',
);

=head2 position

Present only when the Skill object was created through a call to a Character's
C<skill_queue> method. Indicates the position (beginning from zero) of the
Skill in the character's current queue.

=cut

has 'position' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_position',
);

=head2 start_time, end_time

Present only when the Skill object was created through a call to a Character's
C<skill_queue> method. If the character's skill training is paused, these will
be undefined. If the character is actively training, these will return DateTime
objects representing the queued start and end times of the Skill in the queue.

=cut

has 'start_time' => (
    is        => 'rw',
    isa       => 'DateTime',
    traits    => [qw( SetOnce )],
    predicate => 'has_start_time',
);

has 'end_time' => (
    is        => 'rw',
    isa       => 'DateTime',
    traits    => [qw( SetOnce )],
    predicate => 'has_end_time',
);

has 'check_called' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

foreach my $attr (qw( skill_id name description rank required_skills )) {
    before $attr => sub { $_[0]->check_called || $_[0]->check_cache($attr) }
}

=head1 INTERNAL METHODS

The following methods are for internal use only and should not be called by
applications using this library.

=cut

=head2 check_cache

On invocation of the attribute methods, this is called to verify that the cache
has already been populated. This allows the remote API call to be deferred
until it is actually necessary.

=cut

sub check_cache {
    my ($self, $attr) = @_;

    my $has_attr = 'has_' . $attr;

    return if $self->$has_attr;
    $self->update_cache unless $self->is_cached;
    $self->check_called(1);

    my $skill;
    if ($self->has_skill_id && exists $self->Cache->{'skills'}{$self->skill_id}) {
        $skill = $self->Cache->{'skills'}{$self->skill_id};
    } elsif ($self->has_name) {
        my $skill_id = (grep { lc($self->Cache->{'skills'}{$_}{'name'}) eq lc($self->name) }
                            keys %{$self->Cache->{'skills'}})[0];
        $skill = $self->Cache->{'skills'}{$skill_id}
            if defined $skill_id && exists $self->Cache->{'skills'}{$skill_id};
    }

    return unless defined $skill;

    $self->skill_id($skill->{'skill_id'}) unless $self->has_skill_id;
    $self->name($skill->{'name'}) unless $self->has_name;
    $self->description($skill->{'description'}) unless $self->has_description;
    $self->rank($skill->{'rank'}) unless $self->has_rank;

    my @required_skills;
    foreach my $reqskill (@{$skill->{'skills'}}) {
        push(@required_skills, Games::EVE::APIv2::Skill->new(
            $self->keyinfo,
            skill_id => $reqskill->{'skill_id'},
            level    => $reqskill->{'level'},
        ));
    }
    $self->required_skills(\@required_skills);
}

=head2 update_cache

Populates the class attribute cache from the remote API. Short-circuits if the cache
has been populated before. The skill tree changes so rarely, that calling the
remote API should be done as rarely as possible.

=cut

sub update_cache {
    my ($self) = @_;

    return if $self->is_cached;

    my $xml = $self->req->get('eve/SkillTree');

    my %groups;
    my %skills;

    foreach my $groupnode ($xml->findnodes(q{//result/rowset[@name='skillGroups']/row})) {
        $groups{$groupnode->findvalue(q{@groupID})} = $groupnode->findvalue(q{@groupName});
    }

    foreach my $skillnode ($xml->findnodes(q{//rowset[@name='skills']/row})) {
        my $skill_id = $skillnode->findvalue(q{@typeID});

        $skills{$skill_id} = {
            skill_id    => $skill_id,
            name        => $skillnode->findvalue(q{@typeName}),
            description => $skillnode->findvalue(q{description[1]}),
            rank        => $skillnode->findvalue(q{rank[1]}),
            skills      => [],
        };

        foreach my $reqskillnode ($skillnode->findnodes(q{rowset[@name='requiredSkills']/row})) {
            push(@{$skills{$skill_id}{'skills'}}, {
                skill_id => $reqskillnode->findvalue(q{@typeID}),
                level    => $reqskillnode->findvalue(q{@skillLevel})
            });
        }
    }

    $self->Cache({ groups => \%groups, skills => \%skills });
}

__PACKAGE__->meta->make_immutable;

1;
