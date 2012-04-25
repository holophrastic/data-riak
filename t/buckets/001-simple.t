#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dump;
use Digest::MD5 qw/md5_hex/;

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
is($obj->content, 'bar', 'Check the value immediately after insertion');

my $bucket2 = Data::Riak::HTTP::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

my $obj2 = $bucket2->get('foo');
is($obj2->content, 'bar', 'Check the value from a new bucket object');

$bucket2->remove('foo');
$obj = $bucket->get('foo');
$obj2 = $bucket2->get('foo');
is($obj2->status_code, "404", 'Value has been removed from the cloned bucket');
is($obj->status_code, "404", 'Value has been removed from the original bucket');
is($obj2->content, "not found\n", 'Value has been removed from the cloned bucket');
is($obj->content, "not found\n", 'Value has been removed from the original bucket');


$bucket->add('foo', 'value of foo');
$bucket->add('bar', 'value of bar', [{ bucket => $bucket_name, link_type => 'buddy', link_target =>'foo' }]);
$bucket->add('baz', 'value of baz', [{ link_type => 'buddy', link_target =>'foo' }]);
$bucket->add('foo', 'value of foo', [{ link_type => 'not a buddy', link_target =>'bar' }, { link_type => 'not a buddy', link_target =>'baz' }]);

my $foo = $bucket->get('foo');
my $bar = $bucket->get('bar');
my $baz = $bucket->get('baz');

is($foo->content, 'value of foo', 'correct value for foo');
is($bar->content, 'value of bar', 'correct value for bar');
is($baz->content, 'value of baz', 'correct value for baz');

my $arf = $bucket->linkwalk('foo', [[ 'not a buddy', 1 ]]);
ddx($arf);

done_testing;
