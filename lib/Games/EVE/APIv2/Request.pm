package Games::EVE::APIv2::Request;

use Moose;

has 'api' => {
    is  => 'rw',
    isa => 'Str',
};

has 'key_id' => {
    is  => 'rw',
    isa => 'Int',
};

has 'v_code' => {
    is  => 'rw',
    isa => 'Str',
};

sub get {
    my $self = shift;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
