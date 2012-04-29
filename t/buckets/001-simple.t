#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dump;
use Digest::MD5 qw/md5_hex/;

use Test::Exception;
use Test::More;
use Test::Data::Riak;

use Data::Riak::HTTP;
use Data::Riak::HTTP::Bucket;

skip_unless_riak;

my $riak = Data::Riak::HTTP->new;
my $bucket_name = md5_hex(scalar localtime);

my $bucket = Data::Riak::HTTP::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

$bucket->add('foo', 'bar');
my $obj = $bucket->get('foo');
is($obj->value, 'bar', 'Check the value immediately after insertion');

is($obj->name, 'foo', "Name property is inflated correctly");
is($obj->bucket_name, $bucket_name, "Bucket name property is inflated correctly");

$bucket->remove('foo');
$obj = $bucket->get('foo');
is($obj->value, "not found\n", "Calling for a value that doesn't exist returns not found");
is($obj->code, "404", "Calling for a value that doesn't exist returns 404");
dies_ok(sub { $obj->parts }, "Can't call parts on a value that doesn't exist");

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
dies_ok(sub { $baz->parts }, 'Call to parts from a non-multipart message fails');

my $walk_foo = $bucket->linkwalk('foo', [[ 'not a buddy', 1 ]]);
ddx($walk_foo->parts);
my $parts = $walk_foo->parts;
is(scalar @{$parts}, 2, 'Got two parts back from linkwalking foo');
dies_ok(sub { $walk_foo->result }, 'Call to result from a multipart message fails');
my $resultset = $walk_foo->results;
ddx("arf");
isa_ok($resultset, 'Data::Riak::HTTP::ResultSet');
is(scalar @{$resultset->results}, 2, 'Got two Riak::Results back from linkwalking foo');

done_testing;
