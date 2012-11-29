package Data::Riak::Exception::Timeout;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Exception';

has '+message' => (
    default => 'Job timed out',
);

__PACKAGE__->meta->make_immutable;

1;
