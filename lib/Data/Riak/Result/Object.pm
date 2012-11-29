package Data::Riak::Result::Object;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Result';
with 'Data::Riak::Result::WithLocation',
     'Data::Riak::Result::WithLinks',
     'Data::Riak::Result::WithVClock';

has etag => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has last_modified => (
    is       => 'ro',
    isa      => 'HTTP::Headers::ActionPack::DateHeader',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;
