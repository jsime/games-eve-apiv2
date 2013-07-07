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

has 'check_called' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

foreach my $attr (qw( certificate_id description grade category_id category_name class_id class_name )) {
    before $attr => sub { $_[0]->check_called || $_[0]->check_cache($attr) }
}

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
}

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
                };
            }
        }
    }

    $self->Cache({ categories => \%categories, classes => \%classes, certificates => \%certificates });
}

__PACKAGE__->meta->make_immutable;

1;
