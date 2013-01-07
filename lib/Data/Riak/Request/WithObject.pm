package Data::Riak::Request::WithObject;

use Moose::Role;
use namespace::autoclean;

with 'Data::Riak::Request::WithBucket';

has key => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has vector_clock => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_vector_clock',
);

has if_unmodified_since => (
    is        => 'ro',
    predicate => 'has_if_unmodified_since',
);

has if_match => (
    is        => 'ro',
    predicate => 'has_if_match',
);

1;
