#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dump;

use Test::More;
use Test::Data::Riak;

use Data::Riak::HTTP;
use Data::Riak::Bucket;

skip_unless_riak;

my $riak = Data::Riak::HTTP->new;
my $bucket_name = create_test_bucket_name;

my $bucket = Data::Riak::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

my $bucket2 = Data::Riak::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

$bucket->add('foo', 'bar');
my $obj = $bucket->get('foo');

my $value = $obj->value;

is($value, 'bar', 'Original value is bar');

$bucket->add('foo', 'baz');
$obj->sync;

is($obj->value, 'baz', 'Object was updated and old value cleared');

remove_test_bucket($bucket);

done_testing;
