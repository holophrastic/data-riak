package Data::Riak::Exception::ClientError;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Exception';

has '+message' => (
    default => 'Client error',
);

__PACKAGE__->meta->make_immutable;

1;
