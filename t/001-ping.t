#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Data::Riak;

skip_unless_riak;

my $riak = Data::Riak::HTTP->new;
is($riak->ping, 1, 'Riak server to test against');

done_testing;
