package Data::Riak::Async::Request::ListBucketKeys;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Request::ListBucketKeys';
with 'Data::Riak::Async::Request';

__PACKAGE__->meta->make_immutable;

1;
