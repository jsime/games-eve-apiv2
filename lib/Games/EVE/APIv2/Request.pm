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

use Data::Dumper;
use LWP::UserAgent;
use URI::Escape;
use XML::LibXML;

use Moose;
use namespace::autoclean;

has 'api' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_api',
);

has 'key' => (
    is        => 'rw',
    isa       => 'Games::EVE::APIv2::Key',
    predicate => 'has_key',
);

has 'key_id' => (
    is        => 'rw',
    isa       => 'Int',
    predicate => 'has_key_id',
);

has 'v_code' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_v_code',
);

=head1 EXPORT

This library exports nothing but its constructor.

=head1 SUBROUTINES/METHODS

=head2 get

When invoked, this method makes a remote HTTPS call to the CCP API endpoint
specified. While the parameters differ between API methods, they all require
at the very least the path to the API method and the standard Key ID and
Verification Code.

Some API calls require additional parameters, beyond just key information
(which is included automatically, based on the key_id/v_code pair or key
object passed in during construction). For these API calls, the API name
should be followed by a list of key/value pairs (a bare hash, not a hash
reference) for those parameters.

As an example, calling the character sheet API requires supplying a
Character ID. The second example below demonstrates this usage. Note that
the key names must match the URL parameters documented for CCP's API.

Examples:

    $xml = $eve_req->get('account/APIKeyInfo');
    $xml = $eve_req->get('char/CharacterSheet', characterID => 12345 );

Note that the API method is named by only the path portion of the official
CCP URL, minus the file extensions generally present.

The return value is an XML::LibXML document object on success. On all failures,
C<die()> is called.

=cut

sub get {
    my $self = shift;
    my $api = shift;

    die "No API path specified." unless defined $api && length($api) > 0;

    my %opts = @_;

    if (exists $opts{'key_id'}) {
        $opts{'keyID'} = $opts{'key_id'};
        delete $opts{'key_id'};
    }
    if (exists $opts{'v_code'}) {
        $opts{'vCode'} = $opts{'v_code'};
        delete $opts{'v_code'};
    }

    $opts{'keyID'} = $self->key->key_id if $self->has_key;
    $opts{'vCode'} = $self->key->v_code if $self->has_key;

    # The following API calls cannot be made with key information (they don't
    # require it, and will actually error out if given key info).
    my @no_key_apis = qw(
        eve/AllianceList
        eve/CertificateTree
        eve/SkillTree
    );

    # The following API calls take a character ID, but should only be given a
    # keyid/vcode pair if the current key is valid for that character. Otherwise
    # the key information should be omitted.
    my @charid_apis = qw(
        char/CharacterSheet
    );

    # Same as above, but for corporations instead of characters.
    my @corpid_apis = qw(
        corp/CorporationSheet
    );

    if (grep { $api eq $_ } @no_key_apis) {
        delete $opts{'keyID'} if exists $opts{'keyID'};
        delete $opts{'vCode'} if exists $opts{'vCode'};
    } elsif ($self->has_key) {
        if (exists $opts{'characterID'} && grep { $api eq $_ } @charid_apis) {
            unless ($self->key->for_character($opts{'characterID'})) {
                delete $opts{'keyID'} if exists $opts{'keyID'};
                delete $opts{'vCode'} if exists $opts{'vCode'};
            }
        }

        if (exists $opts{'corporationID'} && grep { $api eq $_ } @corpid_apis) {
            unless ($self->key->for_corporation($opts{'corporationID'})) {
                delete $opts{'keyID'} if exists $opts{'keyID'};
                delete $opts{'vCode'} if exists $opts{'vCode'};
            }
        }
    }

    my $api_url = 'https://api.eveonline.com/' . $api . '.xml.aspx?' .
        (join('&', map { uri_escape($_) . '=' . uri_escape($opts{$_}) } sort keys %opts)) || '';

    my $ua = LWP::UserAgent->new();
    $ua->agent(sprintf('%s (%s %s)', $ua->_agent, 'Games::EVE::APIv2', $Games::EVE::APIv2::VERSION));

    my $r = $ua->get($api_url);

    die "Error contacting CCP API: " . $r->status_line unless $r->is_success;

    return XML::LibXML->load_xml( string => $r->decoded_content );
}

__PACKAGE__->meta->make_immutable;

1;
