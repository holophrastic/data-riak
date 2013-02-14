package Data::Riak::Async::Request::Ping;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Request::Ping';
with 'Data::Riak::Async::Request';

__PACKAGE__->meta->make_immutable;

1;
