package Data::Riak::Result::VClock;
# ABSTRACT: Result class for requests returning a vector clock

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Result';
with 'Data::Riak::Result::WithVClock';

__PACKAGE__->meta->make_immutable;

1;
