package Data::Riak::Result::VClock;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Result';
with 'Data::Riak::Result::WithVClock';

__PACKAGE__->meta->make_immutable;

1;
