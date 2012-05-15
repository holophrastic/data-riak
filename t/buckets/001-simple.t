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

$bucket->add('foo', 'bar');

my $obj = $bucket->get('foo');
is($obj->value, 'bar', 'Check the value immediately after insertion');

is($obj->name, 'foo', "Name property is inflated correctly");
is($obj->bucket_name, $bucket_name, "Bucket name property is inflated correctly");

try {
    $bucket->get('foo' => { accept => 'application/json' });
} catch {
    is($_->code, "406", "asking for an incompatible content type fails with a 406");
};

$bucket->remove('foo');
try {
    $bucket->get('foo')
} catch {
    is($_->value, "not found\n", "Calling for a value that doesn't exist returns not found");
    is($_->code, "404", "Calling for a value that doesn't exist returns 404");
};

$bucket->add('foo', 'value of foo');
$bucket->add('bar', 'value of bar', { links => [{ bucket => $bucket_name, type => 'buddy', target =>'foo' }] });
$bucket->add('baz', 'value of baz', { links => [{ type => 'buddy', target =>'foo' }] });
$bucket->add('foo', 'value of foo', { links => [{ type => 'not a buddy', target =>'bar' }, { type => 'not a buddy', target =>'baz' }] });

my $foo = $bucket->get('foo');
my $bar = $bucket->get('bar');
my $baz = $bucket->get('baz');

is($foo->value, 'value of foo', 'correct value for foo');
is($bar->value, 'value of bar', 'correct value for bar');
is($baz->value, 'value of baz', 'correct value for baz');

my $resultset = $bucket->linkwalk('foo', [[ 'not a buddy', '_' ]]);
isa_ok($resultset, 'Data::Riak::ResultSet');
is(scalar @{$resultset->results}, 2, 'Got two Riak::Results back from linkwalking foo');

my $dw_results = $bucket->linkwalk('bar', [ [ 'buddy', '_' ], [ $bucket_name, 'not a buddy', '_' ] ]);
is(scalar $dw_results->all, 2, 'Got two Riak::Results back from linkwalking bar');

remove_test_bucket($bucket);

done_testing;




