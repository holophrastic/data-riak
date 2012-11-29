package Data::Riak::Result::SingleObject;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Result';
with 'Data::Riak::Result::WithLocation',
     'Data::Riak::Result::WithLinks',
     'Data::Riak::Result::Single';

__PACKAGE__->meta->make_immutable;

1;
