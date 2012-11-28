package Data::Riak::Request::WithObject;

use Moose::Role;
use namespace::autoclean;

with 'Data::Riak::Request::WithBucket';

has key => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;
