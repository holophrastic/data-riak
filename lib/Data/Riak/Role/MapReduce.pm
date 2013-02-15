package Data::Riak::Role::MapReduce;

use Moose::Role;
use namespace::autoclean;

has inputs => (
    is       => 'ro',
    isa      => 'ArrayRef | Str | HashRef',
    required => 1
);

has phases => (
    is       => 'ro',
    isa      => 'ArrayRef[Data::Riak::MapReduce::Phase]',
    required => 1
);

1;
