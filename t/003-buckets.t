#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Data::Riak;
use JSON::XS qw[ decode_json ];

use Data::Riak;

skip_unless_riak;

my $riak = Data::Riak->new(transport => Data::Riak::HTTP->new);

# TODO : remove this test, it is not advisable

my $result = $riak->_buckets;
isa_ok( $result, 'Data::Riak::Result');

my $value = decode_json( $result->value );
ok( exists $value->{'buckets'}, '... got buckets' );
is( ref $value->{'buckets'}, 'ARRAY', '... got an ARRAY of buckets' );

done_testing;
