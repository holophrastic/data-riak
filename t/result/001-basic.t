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

is($obj->name, 'foo', '... the name of the item is foo');
is($obj->bucket_name, $bucket->name, '... the name of the bucket is as expected');
is($obj->location, ($obj->riak->base_uri . 'buckets/' . $bucket->name . '/keys/foo'), '... got the right location of the object');
is($obj->value, 'bar', '... the value is bar');

is($obj->status_code, 200, '... got the right status code');
isa_ok($obj->http_message, 'HTTP::Message');

is($obj->riak, $bucket->riak, 'Derived host is correct');

remove_test_bucket($bucket);

done_testing;
