package Data::Riak::Exception::ObjectNotFound;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Exception';

has '+message' => (
    default => 'Object not found',
);

__PACKAGE__->meta->make_immutable;

1;
