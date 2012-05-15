#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Data::Riak;

use Data::Riak;
use Data::Riak::Bucket;

skip_unless_riak;

my $bucket = Data::Riak::Bucket->new({
    name => create_test_bucket_name,
    riak => Data::Riak->new(transport => Data::Riak::HTTP->new)
});

is(exception {
    $bucket->add('foo', 'bar')
}, undef, '... got no exception adding element to the bucket');

my $obj = $bucket->get('foo');
isa_ok($obj, 'Data::Riak::Result');

my $value = $obj->value;
is($value, 'bar', 'Value is bar');

is($obj->riak, $bucket->riak, 'Derived host is correct');

remove_test_bucket($bucket);

done_testing;
