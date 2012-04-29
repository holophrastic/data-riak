package Test::Data::Riak;

use strict;
use warnings;

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
    my $up = Data::Riak::HTTP->new->ping;
    unless($up) {
		warn 'Riak did not answer, skipping tests';
        done_testing;
        exit;
    };
    return $up;
}
