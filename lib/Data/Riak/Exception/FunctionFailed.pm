package Data::Riak::Exception::FunctionFailed;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Exception';

has '+message' => (
    default => 'map or reduce function failed',
);

__PACKAGE__->meta->make_immutable;

1;
