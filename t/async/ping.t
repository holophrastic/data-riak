use strict;
use warnings;
use Test::More 0.89;
use Test::Data::Riak;

use AnyEvent;
use Data::Riak::Async;

BEGIN {
    skip_unless_riak;
}

my $t = Data::Riak::Async::HTTP->new(riak_transport_args);

my $riak = Data::Riak::Async->new({ transport => $t });

my $cv = AE::cv;
$riak->ping(sub { $cv->send(@_) });
ok $cv->recv, 'Riak server to test against';

done_testing;

