#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Data::Riak;

use Data::Riak;
use Data::Riak::Bucket;

skip_unless_riak;

my $riak = Data::Riak->new(transport => Data::Riak::HTTP->new);
my $bucket_name = create_test_bucket_name;

my $bucket = Data::Riak::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

my $bucket2 = Data::Riak::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

is(exception {
    $bucket->add('foo', 'bar')
}, undef, '... got no exception adding element to the bucket');

my $obj = $bucket->get('foo');
isa_ok($obj, 'Data::Riak::Result');

my $value = $obj->value;
is($value, 'bar', 'Original value is bar');

$bucket->add('foo', 'baz');

is(exception {
    $obj->sync;
}, undef, '... got no exception syncing an item');

is($obj->value, 'baz', 'Object was updated and old value cleared');

remove_test_bucket($bucket);

done_testing;
