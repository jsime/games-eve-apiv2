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
    is     => 'rw',
    isa    => 'Str',
    traits => [qw( SetOnce )],
);

sub update_cache {
    my ($self) = @_;

    my $xml = $self->req->get('eve/SkillTree');

    my %groups;
    my %skills;

    foreach my $groupnode ($xml->findnodes(q{//result/rowset[@name='skillGroups']/row})) {
        $groups{$groupnode->findvalue(q{@groupID})} = $groupnode->findvalue(q{@groupName});
    }

    foreach my $skillnode ($xml->findnodes(q{//rowset[@name='skills']/row})) {
        $skills{$skillnode->findvalue(q{@typeID})} = {
            name        => $skillnode->findvalue(q{@typeName}),
            description => $skillnode->findvalue(q{description[1]}),
        }
    }

    $self->Cache({ groups => \%groups, skills => \%skills });
}

sub BUILD {
    my ($self) = @_;

    $self->update_cache unless $self->is_cached;

    my $skill_id;
    if ($self->has_skill_id) {
        $skill_id = $self->skill_id;
    } elsif ($self->has_name) {
        $skill_id = (grep { lc($self->Cache->{'skills'}{$_}{'name'}) eq lc($self->name) }
                        keys %{$self->Cache->{'skills'}})[0];
    }

    die "Cannot look up skill with at least an ID or a name." unless defined $skill_id;
    die "Invalid Skill ID: $skill_id" unless exists $self->Cache->{'skills'}{$skill_id};

    my $skill = $self->Cache->{'skills'}{$skill_id};

    $self->skill_id($skill_id) unless $self->has_skill_id;
    $self->name($skill->{'name'}) unless $self->has_name;
    $self->description($skill->{'description'});
}

__PACKAGE__->meta->make_immutable;

1;
