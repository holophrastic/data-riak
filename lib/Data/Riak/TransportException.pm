package Data::Riak::TransportException;

use Moose;
use namespace::autoclean;

extends 'Throwable::Error';

has request => (
    is       => 'ro',
    isa      => 'Data::Riak::Transport::Request',
    required => 1,
);

has response => (
    is       => 'ro',
    isa      => 'Data::Riak::Transport::Response',
    required => 1,
    handles  => [qw(code value)],
);

1;
