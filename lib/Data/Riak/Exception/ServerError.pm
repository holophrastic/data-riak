package Data::Riak::Exception::ServerError;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Exception';

has '+message' => (
    default => 'Server error',
);

__PACKAGE__->meta->make_immutable;

1;
