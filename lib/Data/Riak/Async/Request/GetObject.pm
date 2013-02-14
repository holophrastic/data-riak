package Data::Riak::Async::Request::GetObject;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Request::GetObject';
with 'Data::Riak::Async::Request';

__PACKAGE__->meta->make_immutable;

1;
