package Games::EVE::APIv2::Request;

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

sub get {
    my $self = shift;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
