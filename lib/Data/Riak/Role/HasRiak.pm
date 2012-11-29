package Data::Riak::Role::HasRiak;

use Moose::Role;
use namespace::autoclean;

has riak => (
    is       => 'ro',
    isa      => 'Data::Riak',
    required => 1
);

1;
