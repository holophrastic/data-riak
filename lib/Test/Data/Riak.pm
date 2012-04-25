package Test::Data::Riak;

use strict;
use warnings;

use Try::Tiny;
use Test::More;

use Sub::Exporter;

use Data::Riak::HTTP;

my @exports = qw[
    skip_unless_riak
];

Sub::Exporter::setup_exporter({
    exports => \@exports,
    groups  => { default => \@exports }
});

sub skip_unless_riak {
    try {
		# This can be overridden via env vars
        Data::Riak::HTTP->new->ping;
    } catch {
        warn $_;
		warn 'Riak did not answer, skipping tests';
        done_testing;
        exit;
    };
    1;
}
