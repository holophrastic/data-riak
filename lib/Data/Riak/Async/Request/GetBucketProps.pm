package Data::Riak::Async::Request::GetBucketProps;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Request::GetBucketProps';
with 'Data::Riak::Async::Request';

__PACKAGE__->meta->make_immutable;

1;
