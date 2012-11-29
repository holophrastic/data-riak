package Data::Riak::Result::SingleValue;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Result';
with 'Data::Riak::Result::Single';

__PACKAGE__->meta->make_immutable;

1;
