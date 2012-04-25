#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dump;
use Digest::MD5 qw/md5_hex/;

use Test::More;
use Test::Data::Riak;

skip_unless_riak;

my $riak = Data::Riak::HTTP->new;

my $bucket_name = md5_hex(scalar localtime);
ddx($bucket_name);
#is($riak->ping, 1, 'Riak server to test against');

done_testing;
