#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dump;
use Try::Tiny;

use Test::More;
use Test::Memory::Cycle;
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

memory_cycle_ok($bucket, '... bucket is cycle free');
memory_cycle_ok($riak, '... riak is cycle free');

$bucket->add('foo', 'bar');
my $obj = $bucket->get('foo');
is($obj->value, 'bar', 'Check the value immediately after insertion');
is($obj->key, 'foo', "Name property is inflated correctly");

memory_cycle_ok($obj, '... object is cycle free');
memory_cycle_ok($bucket, '... bucket is (still) cycle free');
memory_cycle_ok($riak, '... riak is cycle free');

$bucket->remove('foo');
try {
    $bucket->get('foo');
} catch {
    is($_->code, "404", "Calling for a value that doesn't exist returns 404");
};

memory_cycle_ok($obj, '... object is cycle free');
memory_cycle_ok($bucket, '... bucket is (still) cycle free');
memory_cycle_ok($riak, '... riak is cycle free');

$bucket->add('foo', 'value of foo');
$bucket->add('bar', 'value of bar', { links => [{ bucket => $bucket_name, riaktag => 'buddy', key =>'foo' }] });
$bucket->add('baz', 'value of baz', { links => [{ riaktag => 'buddy', key =>'foo' }] });
$bucket->add('foo', 'value of foo', { links => [{ riaktag => 'not a buddy', key =>'bar' }, { riaktag => 'not a buddy', key =>'baz' }] });

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

my $resultset = $bucket->linkwalk('foo', [[ 'not a buddy', '_' ]]);
isa_ok($resultset, 'Data::Riak::ResultSet');
is(scalar @{$resultset->results}, 2, 'Got two Riak::Results back from linkwalking foo');

memory_cycle_ok($resultset, '... resultset is cycle free');
memory_cycle_ok($bucket, '... bucket is (still) cycle free');
memory_cycle_ok($riak, '... riak is cycle free');

my $dw_results = $bucket->linkwalk('bar', [ [ 'buddy', '_' ], [ $bucket_name, 'not a buddy', '_' ] ]);
is(scalar @{$dw_results->results}, 2, 'Got two Riak::Results back from linkwalking bar');

memory_cycle_ok($dw_results, '... dw_results is cycle free');
memory_cycle_ok($bucket, '... bucket is (still) cycle free');
memory_cycle_ok($riak, '... riak is cycle free');

remove_test_bucket($bucket);

done_testing;




