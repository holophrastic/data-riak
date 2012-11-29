package Data::Riak::Exception::ConditionFailed;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Exception';

has '+message' => (
    default => 'Condition failed',
);

__PACKAGE__->meta->make_immutable;

1;
