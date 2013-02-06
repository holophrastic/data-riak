package Data::Riak::Exception;

use Moose;
use namespace::autoclean;

extends 'Throwable::Error' => { -version => '0.200003' };

has request => (
    is       => 'ro',
    does     => 'Data::Riak::Request',
    required => 1,
);

has transport_request => (
    is       => 'ro',
    does     => 'Data::Riak::Transport::Request',
    required => 1,
);

has transport_response => (
    is       => 'ro',
    does     => 'Data::Riak::Transport::Response',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;
