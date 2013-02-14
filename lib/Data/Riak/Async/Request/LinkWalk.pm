package Data::Riak::Async::Request::LinkWalk;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Request::LinkWalk';
with 'Data::Riak::Async::Request';

__PACKAGE__->meta->make_immutable;

1;
