package Test::Data::Riak;

use strict;
use warnings;

use Try::Tiny;
use Test::More;
use Digest::MD5 qw/md5_hex/;

use Sub::Exporter;

use Data::Riak;
use Data::Riak::HTTP;
use namespace::clean;

my @exports = qw[
    skip_unless_riak
    skip_unless_leveldb_backend
    remove_test_bucket
    create_test_bucket_name
];

sub _build_transport {
    my ($protocol) = @_;

    Data::Riak->new({
        transport => Data::Riak::HTTP->new({
            protocol  => $protocol,
        }),
    });
}

sub _build_exports {
    my ($self, $meth, $args, $defaults) = @_;

    my $transport = $args->{transport};

    return {
        remove_test_bucket          => \&remove_test_bucket,
        create_test_bucket_name     => \&create_test_bucket_name,
        skip_unless_riak            => sub { skip_unless_riak($transport, @_) },
        skip_unless_leveldb_backend => sub {
            skip_unless_leveldb_backend($transport, @_)
        },
    };
}

my $import = Sub::Exporter::build_exporter({
    groups     => { default => \&_build_exports },
    into_level => 1,
});

use List::AllUtils 'any';
sub import {
    my ($class, @opts) = @_;
    my $https = any { $_ eq '-https' } @opts;
    $import->($class, -default => {
        transport => _build_transport($https ? 'https' : 'http'),
    });
}

sub create_test_bucket_name {
	my $prefix = shift || 'data-riak-test';
    return $prefix . '-' . md5_hex(scalar localtime)
}

sub skip_unless_riak {
    my ($transport) = @_;

    my $up = $transport->ping;
    unless($up) {
        plan skip_all => 'Riak did not answer, skipping tests'
    };
    return $up;
}

sub skip_unless_leveldb_backend {
    my ($transport) = @_;

    my $status = try {
        $transport->status;
    }
    catch {
        warn $_;
        plan skip_all => "Failed to identify the Riak node's storage backend";
    };

    plan skip_all => 'This test requires the leveldb Riak storage backend'
        unless $status->{storage_backend} eq 'riak_kv_eleveldb_backend';
    return;
}

sub remove_test_bucket {
    my $bucket = shift;

    try {
        $bucket->remove_all;
        Test::More::diag "Removing test bucket so sleeping for a moment to allow riak to eventually be consistent ..."
              if $ENV{HARNESS_IS_VERBOSE};
        my $keys = $bucket->list_keys;
        while ( $keys && @$keys ) {
            sleep(1);
            $keys = $bucket->list_keys;
        }
    } catch {
        isa_ok $_, 'Data::Riak::Exception';
    };
}

