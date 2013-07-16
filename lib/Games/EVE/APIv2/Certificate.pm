package Games::EVE::APIv2::Certificate;

=head1 NAME

Games::EVE::APIv2::Certificate

=head1 SYNOPSIS

Subclass providing access to EVE Online's certificate tree information. Will perform
a remote API call the first time any certificate tree information is requested, and
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

has 'certificate_id' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_certificate_id',
);

has 'description' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_description',
);

has 'grade' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_grade',
);

has 'category_id' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_category_id',
);

has 'category_name' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_category_name',
);

has 'class_id' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_class_id',
);

has 'class_name' => (
    is        => 'rw',
    isa       => 'Str',
    traits    => [qw( SetOnce )],
    predicate => 'has_class_name',
);

has 'required_certificates' => (
    is        => 'rw',
    isa       => 'ArrayRef[Games::EVE::APIv2::Certificate]',
    traits    => [qw( SetOnce )],
    predicate => 'has_required_certificates',
);

has 'required_skills' => (
    is        => 'rw',
    isa       => 'ArrayRef[Games::EVE::APIv2::Skill]',
    traits    => [qw( SetOnce )],
    predicate => 'has_required_skills',
);

has 'check_called' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

foreach my $attr (qw( certificate_id description grade category_id category_name class_id class_name required_certificates required_skills )) {
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

    my $certificate;
    if ($self->has_certificate_id && exists $self->Cache->{'certificates'}{$self->certificate_id}) {
        $certificate = $self->Cache->{'certificates'}{$self->certificate_id};
    }

    return unless defined $certificate;

    $self->certificate_id($certificate->{'certificate_id'}) unless $self->has_certificate_id;
    $self->description($certificate->{'description'}) unless $self->has_description;
    $self->grade($certificate->{'grade'}) unless $self->has_grade;

    $self->category_id($certificate->{'category_id'}) unless $self->has_category_id;
    $self->category_name($self->Cache->{'categories'}{$certificate->{'category_id'}})
        unless $self->has_category_name;

    $self->class_id($certificate->{'class_id'}) unless $self->has_class_id;
    $self->class_name($self->Cache->{'classes'}{$certificate->{'class_id'}})
        unless $self->has_class_name;

    $self->required_certificates($certificate->{'certificates'}) unless $self->has_required_certificates;
    $self->required_skills($certificate->{'skills'}) unless $self->has_required_skills;
}

=head2 update_cache

Populates the class attribute cache from the remote API. Short-circuits if the cache
has been populated before. The certificate tree changes so rarely, that calling the
remote API should be done as rarely as possible.

=cut

sub update_cache {
    my ($self) = @_;

    return if $self->is_cached;

    my $xml = $self->req->get('eve/CertificateTree');

    my %categories;
    my %classes;
    my %certificates;

    foreach my $categorynode ($xml->findnodes(q{//result/rowset[@name='categories']/row})) {
        my $category_id = $categorynode->findvalue(q{@categoryID});
        my $category_name = $categorynode->findvalue(q{@categoryName});

        $categories{$category_id} = $category_name;

        foreach my $classnode ($categorynode->findnodes(q{rowset[@name='classes']/row})) {
            my $class_id = $classnode->findvalue(q{@classID});
            my $class_name = $classnode->findvalue(q{@className});

            $classes{$class_id} = $class_name;

            foreach my $certificatenode ($classnode->findnodes(q{rowset[@name='certificates']/row})) {
                my $certificate_id = $certificatenode->findvalue(q{@certificateID});

                $certificates{$certificate_id} = {
                    certificate_id => $certificate_id,
                    grade          => $certificatenode->findvalue(q{@grade}),
                    description    => $certificatenode->findvalue(q{@description}),
                    category_id    => $category_id,
                    class_id       => $class_id,
                    certificates   => [],
                    skills         => [],
                };

                foreach my $reqcertnode ($certificatenode->findnodes(q{rowset[@name='requiredCertificates']/row})) {
                    push(@{$certificates{$certificate_id}{'certificates'}},
                        Games::EVE::APIv2::Certificate->new(
                            key            => $self->key,
                            certificate_id => $reqcertnode->findvalue(q{@certificateID}),
                            grade          => $reqcertnode->findvalue(q{@grade}),
                        )
                    );
                }

                foreach my $skillnode ($certificatenode->findnodes(q{rowset[@name='requiredSkills']/row})) {
                    push(@{$certificates{$certificate_id}{'skills'}},
                        Games::EVE::APIv2::Skill->new(
                            key      => $self->key,
                            skill_id => $skillnode->findvalue(q{@typeID}),
                            level    => $skillnode->findvalue(q{@level}),
                        )
                    );
                }
            }
        }
    }

    $self->Cache({ categories => \%categories, classes => \%classes, certificates => \%certificates });
}

__PACKAGE__->meta->make_immutable;

1;
