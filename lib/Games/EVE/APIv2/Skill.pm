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

class_has 'Cache' => (
    is        => 'rw',
    isa       => 'HashRef[HashRef]',
    predicate => 'is_cached'
);

has 'skill_id' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_skill_id',
);

has 'name' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_name',
);

has 'description' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_description',
);

has 'check_called' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

foreach my $attr (qw( skill_id name description )) {
    before $attr => sub { $_[0]->check_called || $_[0]->check_cache($attr) }
}

sub check_cache {
    my ($self, $attr) = @_;

    my $has_attr = 'has_' . $attr;

    return if $self->is_cached || $self->$has_attr;
    $self->update_cache;
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
}

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
        }
    }

    $self->Cache({ groups => \%groups, skills => \%skills });
}

__PACKAGE__->meta->make_immutable;

1;
