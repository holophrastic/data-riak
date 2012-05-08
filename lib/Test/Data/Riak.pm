package Test::Data::Riak;

use strict;
use warnings;

use Test::More;

use Sub::Exporter;

use Data::Riak::HTTP;

my @exports = qw[
    skip_unless_riak
    remove_test_bucket
    create_test_bucket_name
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

sub remove_test_bucket {
    my $bucket = shift;
    $bucket->remove_all;
    Test::More::diag "Removing test bucket so sleeping for a moment to allow riak to eventually be consistent ...";
    my $keys = $bucket->list_keys;
    while ( $keys && @$keys ) {
        sleep(1);
        $keys = $bucket->list_keys;
    }
}

