package Data::Riak::Async::Request::RemoveObject;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Request::RemoveObject';
with 'Data::Riak::Async::Request';

__PACKAGE__->meta->make_immutable;

1;
