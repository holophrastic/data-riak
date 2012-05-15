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

is(exception {
    $bucket->add('bar', 'value of bar', { links => [{ bucket => $bucket_name, type => 'buddy', target =>'foo' }] });
    $bucket->add('baz', 'value of baz', { links => [{ type => 'buddy', target =>'foo' }] });
    $bucket->add('foo', 'value of foo', { links => [{ type => 'not a buddy', target =>'bar' }, { type => 'not a buddy', target =>'baz' }] });
}, undef, '... no exception while adding links');

my $foo = $bucket->get('foo');
isa_ok($foo, 'Data::Riak::Result');

isa_ok($foo->links, 'HTTP::Headers::ActionPack::LinkList');

my ($bar_link, $baz_link, $up_link) = $foo->links->iterable;

isa_ok($bar_link, 'HTTP::Headers::ActionPack::LinkHeader');
is($bar_link->href, ('/buckets/' . $bucket_name . '/keys/bar'), '... got the right href');
is($bar_link->params->{'riaktag'}, 'not a buddy', '... got the right riak tag');

isa_ok($baz_link, 'HTTP::Headers::ActionPack::LinkHeader');
is($baz_link->href, ('/buckets/' . $bucket_name . '/keys/baz'), '... got the right href');
is($baz_link->params->{'riaktag'}, 'not a buddy', '... got the right riak tag');

isa_ok($up_link, 'HTTP::Headers::ActionPack::LinkHeader');
is($up_link->href, ('/buckets/' . $bucket_name), '... got the right href');
is($up_link->rel, 'up', '... got the right rel');

my $resultset = $foo->linkwalk([[ 'not a buddy', 1 ]]);
isa_ok($resultset, 'Data::Riak::ResultSet');

is(scalar @{$resultset->results}, 2, 'Got two Riak::Results back from linkwalking foo');

my ($buddy1, $buddy2) = $resultset->all;

isa_ok($buddy1, 'Data::Riak::Result');
is($buddy1->value, 'value of ' . $buddy1->name, '... go the right value');

{
    my ($foo_link, $up_link) = $buddy1->links->iterable;

    isa_ok($foo_link, 'HTTP::Headers::ActionPack::LinkHeader');
    is($foo_link->href, ('/buckets/' . $bucket_name . '/keys/foo'), '... got the right href');
    is($foo_link->params->{'riaktag'}, 'buddy', '... got the right riak tag');

    isa_ok($up_link, 'HTTP::Headers::ActionPack::LinkHeader');
    is($up_link->href, ('/buckets/' . $bucket_name), '... got the right href');
    is($up_link->rel, 'up', '... got the right rel');
}

isa_ok($buddy2, 'Data::Riak::Result');
is($buddy2->value, 'value of ' . $buddy2->name, '... go the right value');

{
    my ($foo_link, $up_link) = $buddy2->links->iterable;

    isa_ok($foo_link, 'HTTP::Headers::ActionPack::LinkHeader');
    is($foo_link->href, ('/buckets/' . $bucket_name . '/keys/foo'), '... got the right href');
    is($foo_link->params->{'riaktag'}, 'buddy', '... got the right riak tag');

    isa_ok($up_link, 'HTTP::Headers::ActionPack::LinkHeader');
    is($up_link->href, ('/buckets/' . $bucket_name), '... got the right href');
    is($up_link->rel, 'up', '... got the right rel');
}

remove_test_bucket($bucket);

done_testing;
