package Data::Riak::Exception::MultipleSiblingsAvailable;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Exception';

has '+message' => (
    default => 'Multiple siblings available',
);

__PACKAGE__->meta->make_immutable;

1;
