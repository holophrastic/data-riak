package Data::Riak::Result::MaybeVClock;
# ABSTRACT: Result class for requests returning a vector clock

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Result';
with 'Data::Riak::Result::MaybeWithVClock';

__PACKAGE__->meta->make_immutable;

1;
