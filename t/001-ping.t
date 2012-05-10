#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Data::Riak;

use Data::Riak;

skip_unless_riak;

my $riak = Data::Riak->new(transport => Data::Riak::HTTP->new);
ok($riak->ping, 'Riak server to test against');

done_testing;
