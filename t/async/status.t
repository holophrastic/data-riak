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

my $cv = AE::cv;
$riak->status(
    sub { $cv->send(@_) },
    sub { $cv->croak(@_) },
);

is ref $cv->recv, 'HASH';

done_testing;
