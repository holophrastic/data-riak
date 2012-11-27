package Data::Riak::Result::Object;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Result';
with 'Data::Riak::Result::WithLocation',
     'Data::Riak::Result::WithLinks';

__PACKAGE__->meta->make_immutable;

1;
