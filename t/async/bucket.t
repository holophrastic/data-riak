use strict;
use warnings;
use Test::More 0.89;

use Test::Data::Riak;

BEGIN {
    skip_unless_riak;
}

use AnyEvent;
use Data::Riak::Async;
use Data::Riak::Async::HTTP;

my $riak = Data::Riak::Async->new({
    transport => Data::Riak::Async::HTTP->new(riak_transport_args),
});

my $bucket = $riak->bucket(create_test_bucket_name);
isa_ok $bucket, 'Data::Riak::Async::Bucket';

my $cv = AE::cv;
$bucket->count(
    sub { $cv->send(@_) },
    sub { $cv->croak(@_) },
);
is $cv->recv, 0;

done_testing;
