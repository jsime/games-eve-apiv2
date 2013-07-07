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

foreach my $attr (qw( certificate_id name description )) {
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
    } elsif ($self->has_name) {
        my $certificate_id = (grep { lc($self->Cache->{'certificates'}{$_}{'name'}) eq lc($self->name) }
                                  keys %{$self->Cache->{'certificates'}})[0];
        $certificate = $self->Cache->{'certificates'}{$certificate_id}
            if defined $certificate_id && exists $self->Cache->{'certificates'}{$certififcate_id};
    }

    return unless defined $certificate;

    $self->certificate_id($certificate->{'certificate_id'}) unless $self->has_certificate_id;
    $self->name($certificate->{'name'}) unless $self->has_name;
    $self->description($certificate->{'description'}) unless $self->has_description;
}

sub update_cache {
    my ($self) = @_;

    return if $self->is_cached;

    my $xml = $self->req->get('eve/CertificateTree');

    my %categories;
    my %certificates;

    foreach my $categorynode ($xml->findnodes(q{//result/rowset[@name='categories']/row})) {
        $categories{$categorynode->findvalue(q{@categoryID})} = $categorynode->findvalue(q{@categoryName});
    }

    foreach my $certificatenode ($xml->findnodes(q{//rowset[@name='certificates']/row})) {
        my $certificate_id = $certificatenode->findvalue(q{@certificateID});

        $certificates{$certificate_id} = {
            certificate_id => $certificate_id,
            grade          => $certificatenode->findvalue(q{@grade}),
            description    => $certificatenode->findvalue(q{@description}),
        }
    }

    $self->Cache({ categories => \%categories, certificates => \%certificates });
}

__PACKAGE__->meta->make_immutable;

1;
