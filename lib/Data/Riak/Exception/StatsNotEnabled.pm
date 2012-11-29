package Data::Riak::Exception::StatsNotEnabled;

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Exception';

has '+message' => (
    default => 'Unable to retrieve stats. riak_kv_stat is not enabled',
);

__PACKAGE__->meta->make_immutable;

1;
