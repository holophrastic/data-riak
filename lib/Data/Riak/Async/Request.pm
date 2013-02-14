package Data::Riak::Async::Request;

use Moose::Role;
use namespace::autoclean;

has cb => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

1;
