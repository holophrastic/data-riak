package Data::Riak::Role::HasRiak;

use Moose::Role;
use namespace::autoclean;

has riak => (
    is       => 'ro',
    does     => 'Data::Riak::Role::Frontend',
    required => 1,
);

1;
