package Data::Riak::Result::SingleObject;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Result::Object';
with 'Data::Riak::Result::Single';

__PACKAGE__->meta->make_immutable;

1;
