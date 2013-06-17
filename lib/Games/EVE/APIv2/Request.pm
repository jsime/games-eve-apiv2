package Games::EVE::APIv2::Request;

=head1 NAME

Games::EVE::APIv2::Request

=head1 SYNOPSIS

API Request handler for C<Games::EVE::APIv2>. Wraps up making HTTP(s) calls to CCP's
API endpoints and getting the responses back into a usable XML::LibXML object.

Using the C<get()> method is the primary interface for this module.

=cut

use strict;
use warnings FATAL => 'all';
use namespace::autoclean;

use LWP::UserAgent;
use XML::LibXML;

use Moose;

has 'api' => (
    is        => 'rw',
    isa       => 'Str',
    clearer   => 'clear_api',
    predicate => 'has_api',
);

has 'key_id' => (
    is        => 'rw',
    isa       => 'Int',
    clearer   => 'clear_key_id',
    predicate => 'has_key_id',
);

has 'v_code' => (
    is        => 'rw',
    isa       => 'Str',
    clearer   => 'clear_v_code',
    predicate => 'has_v_code',
);

=head1 EXPORT

This library exports nothing but its constructor.

=head1 SUBROUTINES/METHODS

=head2 get

When invoked, this method makes a remote HTTP(s) call to the CCP API endpoint
specified. While the parameters differ between API methods, they all require
at the very least the path to the API method and the standard Key ID and
Verification Code.

This method will use the Key ID and Verification Code supplied during object
construction, but you may also override these on a per-call basis by passing
in an options hash (keys: C<key_id> and C<v_code>).

The API method to be called may be specified in either of two ways: as the
first argument in scalar form, or as part of the options hash with the key
name C<api>.

Examples:

    $xml = $eve_req->get('account/APIKeyInfo');
    $xml = $eve_req->get('account/APIKeyInfo', key_id => '123', v_code => 'abc');
    $xml = $eve_req->get( api => 'account/APIKeyInfo' );

Note that the API method is named by only the path portion of the official
CCP URL, minus the file extensions generally present.

=cut

sub get {
    my $self = shift;

    my ($api);
    $api = $self->api if $self->has_api;
    $api = shift if defined $_[0] && !ref($_[0]);

    my %opts = @_;
    $api = $opts{'api'} if exists $opts{'api'};

    die "Cannot call APIv2 without API path, Key ID and Verification Code"
        unless defined $api && $self->has_key_id && $self->has_v_code;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
