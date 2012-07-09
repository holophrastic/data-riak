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

my $link = Data::Riak::Link->new(
    bucket => $bucket_name,
    key => 'foo',
    riaktag => 'buddy'
);
isa_ok($link, 'Data::Riak::Link');

try {
    $riak->resolve_link( $link );
} catch {
    is($_->value, "not found\n", "Calling for a value that doesn't exist returns not found");
    is($_->code, "404", "Calling for a value that doesn't exist returns 404");
};

$bucket->add('foo', 'bar');

my $result = $riak->resolve_link( $link );
isa_ok($result, 'Data::Riak::Result');

is($result->key, 'foo', '... got the result we expected');

remove_test_bucket($bucket);

done_testing;


