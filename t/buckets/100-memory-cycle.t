#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dump;

use Test::Exception;
use Test::More;
use Test::Memory::Cycle;
use Test::Data::Riak;

use Data::Riak::HTTP;
use Data::Riak::HTTP::Bucket;

skip_unless_riak;

my $riak = Data::Riak::HTTP->new;
my $bucket_name = create_test_bucket_name;

my $bucket = Data::Riak::HTTP::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

memory_cycle_ok($bucket, '... bucket is cycle free');
memory_cycle_ok($riak, '... riak is cycle free');

$bucket->add('foo', 'bar');
my $obj = $bucket->get('foo');
is($obj->value, 'bar', 'Check the value immediately after insertion');
is($obj->name, 'foo', "Name property is inflated correctly");

memory_cycle_ok($obj, '... object is cycle free');
memory_cycle_ok($bucket, '... bucket is (still) cycle free');
memory_cycle_ok($riak, '... riak is cycle free');

$bucket->remove('foo');
$obj = $bucket->get('foo');
is($obj->code, "404", "Calling for a value that doesn't exist returns 404");

memory_cycle_ok($obj, '... object is cycle free');
memory_cycle_ok($bucket, '... bucket is (still) cycle free');
memory_cycle_ok($riak, '... riak is cycle free');

$bucket->add('foo', 'value of foo');
$bucket->add('bar', 'value of bar', [{ bucket => $bucket_name, type => 'buddy', target =>'foo' }]);
$bucket->add('baz', 'value of baz', [{ type => 'buddy', target =>'foo' }]);
$bucket->add('foo', 'value of foo', [{ type => 'not a buddy', target =>'bar' }, { type => 'not a buddy', target =>'baz' }]);

my $foo = $bucket->get('foo');
my $bar = $bucket->get('bar');
my $baz = $bucket->get('baz');

is($foo->value, 'value of foo', 'correct value for foo');
is($bar->value, 'value of bar', 'correct value for bar');
is($baz->value, 'value of baz', 'correct value for baz');

memory_cycle_ok($foo, '... foo is cycle free');
memory_cycle_ok($bar, '... bar is cycle free');
memory_cycle_ok($baz, '... baz is cycle free');
memory_cycle_ok($bucket, '... bucket is (still) cycle free');
memory_cycle_ok($riak, '... riak is cycle free');

my $walk_foo = $bucket->linkwalk('foo', [[ 'not a buddy', '_' ]]);
my $parts = $walk_foo->parts;
is(scalar @{$parts}, 2, 'Got two parts back from linkwalking foo');

my $resultset = $walk_foo->results;
isa_ok($resultset, 'Data::Riak::HTTP::ResultSet');
is(scalar @{$resultset->results}, 2, 'Got two Riak::Results back from linkwalking foo');

memory_cycle_ok($walk_foo, '... walk_foo is cycle free');
memory_cycle_ok($parts, '... resultset is cycle free');
memory_cycle_ok($resultset, '... resultset is cycle free');
memory_cycle_ok($bucket, '... bucket is (still) cycle free');
memory_cycle_ok($riak, '... riak is cycle free');

my $deep_walk_foo = $bucket->linkwalk('bar', [ [ 'buddy', '_' ], [ $bucket_name, 'not a buddy', '_' ] ]);
my $dw_resultset = $deep_walk_foo->results;
my $dw_results = $dw_resultset->results;
is(scalar @{$dw_results}, 2, 'Got two Riak::Results back from linkwalking bar');

memory_cycle_ok($deep_walk_foo, '... deep_walk_foo is cycle free');
memory_cycle_ok($dw_resultset, '... dw_resultset is cycle free');
memory_cycle_ok($dw_results, '... dw_results is cycle free');
memory_cycle_ok($bucket, '... bucket is (still) cycle free');
memory_cycle_ok($riak, '... riak is cycle free');

remove_test_bucket($bucket);

done_testing;




