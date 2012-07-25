#!/usr/bin/env perl

use strict;
use warnings;

use Try::Tiny;

use Test::More;
use Test::Fatal;
use Test::Data::Riak;

BEGIN {
    skip_unless_riak;
    use_ok('Data::Riak::Link');
}

use Data::Riak;

my $riak = Data::Riak->new(transport => Data::Riak::HTTP->new);
my $bucket_name = create_test_bucket_name;
my $bucket = $riak->bucket( $bucket_name );

$bucket->add('foo', 'bar', {
    links => [
        Data::Riak::Link->new(
            bucket => $bucket->name,
            riaktag => 'buddy',
            key => 'baz'
        )
    ]
});

my $foo = $bucket->get('foo');

$foo->add_link(Data::Riak::Link->new(
    bucket => $bucket->name,
    riaktag => 'buddy',
    key => 'qux'
));

my $server_foo = $bucket->get('foo');

is(scalar @{$server_foo->links}, '3', '... two manual links plus the "up"');

remove_test_bucket($bucket);

done_testing;


