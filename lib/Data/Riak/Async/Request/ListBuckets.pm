package Data::Riak::Async::Request::ListBuckets;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Request::ListBuckets';
with 'Data::Riak::Async::Request';

__PACKAGE__->meta->make_immutable;

1;
