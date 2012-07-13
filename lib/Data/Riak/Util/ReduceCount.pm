package Data::Riak::Util::ReduceCount;

use strict;
use warnings;

use Moose;

extends 'Data::Riak::MapReduce::Phase::Reduce';

has '+language' => (
    default => 'erlang'
);

has '+function' => (
    default => 'reduce_count_inputs'
);

has '+arg' => (
    default => 'filter_notfound'
);

has '+module' => (
    default => 'riak_kv_mapreduce'
);

no Moose;

1;

__END__