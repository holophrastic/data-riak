#!/usr/bin/env perl

use strict;
use warnings;

use Test::Fatal;
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

$bucket->add('bar', 'value of bar', [{ bucket => $bucket_name, type => 'buddy', target =>'foo' }]);
$bucket->add('baz', 'value of baz', [{ type => 'buddy', target =>'foo' }]);
$bucket->add('foo', 'value of foo', [{ type => 'not a buddy', target =>'bar' }, { type => 'not a buddy', target =>'baz' }]);

my $foo = $bucket->get('foo');

my $walk_foo = $foo->linkwalk([[ 'not a buddy', 1 ]]);
my $parts = $walk_foo->parts;
is(scalar @{$parts}, 2, 'Got two parts back from linkwalking foo');
like(exception { $walk_foo->result }, qr/^Can\'t give a single result for a multipart response/, 'Call to result from a multipart message fails');
my $resultset = $walk_foo->results;
isa_ok($resultset, 'Data::Riak::ResultSet');
is(scalar @{$resultset->results}, 2, 'Got two Riak::Results back from linkwalking foo');

remove_test_bucket($bucket);

done_testing;
