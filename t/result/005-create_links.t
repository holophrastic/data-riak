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

my ($bar, $baz);
is(exception {
    $bar = $bucket->add('bar', 'value of bar', { query => { returnbody => 'true' } });
    $baz = $bucket->add('baz', 'value of baz', { query => { returnbody => 'true' } });
}, undef, '... no exception while items');

my $bar_link = $bar->create_link(type => 'not a buddy');
my $baz_link = $baz->create_link(type => 'not a buddy');

is(exception {
    $bucket->add('foo', 'value of foo', { links => [ $bar_link, $baz_link ] });
}, undef, '... no exception while items');

{
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
        my ($up_link) = $buddy1->links->iterable;

        isa_ok($up_link, 'HTTP::Headers::ActionPack::LinkHeader');
        is($up_link->href, ('/buckets/' . $bucket_name), '... got the right href');
        is($up_link->rel, 'up', '... got the right rel');
    }

    isa_ok($buddy2, 'Data::Riak::Result');
    is($buddy2->value, 'value of ' . $buddy2->name, '... go the right value');

    {
        my ($up_link) = $buddy2->links->iterable;

        isa_ok($up_link, 'HTTP::Headers::ActionPack::LinkHeader');
        is($up_link->href, ('/buckets/' . $bucket_name), '... got the right href');
        is($up_link->rel, 'up', '... got the right rel');
    }
}

remove_test_bucket($bucket);

done_testing;
