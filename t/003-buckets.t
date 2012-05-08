#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Data::Riak;
use JSON::XS qw[ decode_json ];

skip_unless_riak;

my $riak = Data::Riak::HTTP->new;

my $response = $riak->buckets;
isa_ok($response, 'Data::Riak::HTTP::Response');

my $result = $response->result;
isa_ok( $result, 'Data::Riak::HTTP::Result');

my $value = decode_json( $result->value );
ok( exists $value->{'buckets'}, '... got buckets' );
is( ref $value->{'buckets'}, 'ARRAY', '... got an ARRAY of buckets' );

done_testing;
