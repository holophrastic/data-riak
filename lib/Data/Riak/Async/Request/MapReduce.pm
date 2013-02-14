package Data::Riak::Async::Request::MapReduce;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Request::MapReduce';
with 'Data::Riak::Async::Request';

__PACKAGE__->meta->make_immutable;

1;
