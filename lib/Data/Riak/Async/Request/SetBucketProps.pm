package Data::Riak::Async::Request::SetBucketProps;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Request::SetBucketProps';
with 'Data::Riak::Async::Request';

__PACKAGE__->meta->make_immutable;

1;
