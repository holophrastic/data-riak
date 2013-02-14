package Data::Riak::Async::Request::StoreObject;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Request::StoreObject';
with 'Data::Riak::Async::Request';

__PACKAGE__->meta->make_immutable;

1;
