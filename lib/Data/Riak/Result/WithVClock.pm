package Data::Riak::Result::WithVClock;

use Moose::Role;
use namespace::autoclean;

has vector_clock => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;
