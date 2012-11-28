package Data::Riak::Exception;

use Moose;
use namespace::autoclean;

extends 'Throwable::Error';

has request => (
    is       => 'ro',
    isa      => 'Data::Riak::Request',
    required => 1,
);

has transport_request => (
    is       => 'ro',
    isa      => 'Data::Riak::Transport::Request',
    required => 1,
);

has transport_response => (
    is       => 'ro',
    isa      => 'Data::Riak::Transport::Response',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;
