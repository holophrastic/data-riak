package Data::Riak::Async::Request::Status;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Request::Status';
with 'Data::Riak::Async::Request';

__PACKAGE__->meta->make_immutable;

1;
