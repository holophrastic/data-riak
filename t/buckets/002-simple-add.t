#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dump;
use Try::Tiny;

use Test::Fatal;
use Test::More;
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

{
    my $result = $bucket->add('foo', 'bar');
    ok(not(defined $result), '... nothing was returned');

    my $obj = $bucket->get('foo');
    is($obj->value, 'bar', 'Check the value immediately after insertion');

    is($obj->key, 'foo', "Name property is inflated correctly");
    is($obj->bucket_name, $bucket_name, "Bucket name property is inflated correctly");
}

{
    my $obj = $bucket->add('bar', 'baz', { query => { returnbody => 'true' } });
    ok(defined $obj, '... something was returned');
    isa_ok($obj, 'Data::Riak::Result');

    is($obj->value, 'baz', 'Check the value immediately after insertion');

    is($obj->key, 'bar', "Name property is inflated correctly");
    is($obj->bucket_name, $bucket_name, "Bucket name property is inflated correctly");
}

remove_test_bucket($bucket);

done_testing;




