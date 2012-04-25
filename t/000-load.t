#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
	use_ok('Data::Riak');
	use_ok('Data::Riak::HTTP');
}

done_testing;
