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

$obj->value('baz');
$obj->save;

my $obj2 = $bucket2->get('foo');
isa_ok($obj2, 'Data::Riak::Result');

my $value2 = $obj2->value;
is($value2, 'baz', 'Got updated value');

remove_test_bucket($bucket);

done_testing;
