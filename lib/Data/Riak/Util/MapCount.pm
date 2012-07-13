package Data::Riak::Util::MapCount;

use strict;
use warnings;

use Moose;

extends 'Data::Riak::MapReduce::Phase::Map';

has '+language' => (
	default => 'erlang'
);

has '+function' => (
    default => 'map_object_value'
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