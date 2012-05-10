#!/usr/bin/env perl

use strict;
use warnings;

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

$bucket->add('foo', 'bar');
my $obj = $bucket->get('foo');

my $value = $obj->value;

is($value, 'bar', 'Value is bar');

my $derived_riak = $obj->riak;
is($derived_riak->host, $riak->host, 'Derived host is correct');
is($derived_riak->port, $riak->port, 'Derived port is correct');

remove_test_bucket($bucket);

done_testing;
