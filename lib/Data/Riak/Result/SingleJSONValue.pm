package Data::Riak::Result::SingleJSONValue;

use Moose;
use JSON 'decode_json';
use namespace::autoclean;

extends 'Data::Riak::Result';
with 'Data::Riak::Result::JSONValue',
     'Data::Riak::Result::Single';

__PACKAGE__->meta->make_immutable;

1;
