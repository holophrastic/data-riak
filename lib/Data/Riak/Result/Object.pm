package Data::Riak::Result::Object;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Result';
with 'Data::Riak::Result::WithLocation';

__PACKAGE__->meta->make_immutable;

1;
