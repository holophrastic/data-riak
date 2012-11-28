package Data::Riak::Request::WithBucket;

use Moose::Role;
use namespace::autoclean;

with 'Data::Riak::Request';

has bucket_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;
