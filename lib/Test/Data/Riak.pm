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

sub _env_key {
    my ($key, $https) = @_;
    sprintf 'TEST_DATA_RIAK_HTTP%s_%s', ($https ? 'S' : ''), $key;
}

my %defaults = (
    host     => '127.0.0.1',
    port     => 8098,
    timeout  => 15,
    protocol => 'http',
);

for my $opt (keys %defaults) {
    my $code = sub {
        my ($https) = @_;
        my $env_key = _env_key uc $opt, $https;
        exists $ENV{$env_key} ? $ENV{$env_key} : $defaults{$opt}
    };

    no strict 'refs';
    *{"_default_${opt}"} = $code;
}

sub _build_transport_args {
    my ($args) = @_;

    my $protocol = exists $args->{protocol}
        ? $args->{protocol} : _default_protocol();

    my $https = $protocol eq 'https';

    return {
        protocol => $protocol,
        timeout  => (exists $args->{timeout}
                         ? $args->{timeout} : _default_timeout($https)),
        host     => (exists $args->{host}
                         ? $args->{host} : _default_host($https)),
        port     => (exists $args->{port}
                         ? $args->{port} : _default_port($https)),
    };
}

sub _build_transport {
    my $args = _build_transport_args(@_);
    ($args, Data::Riak->new({
        transport => Data::Riak::HTTP->new($args),
    }));
}

sub _build_riak_transport_args {
    my ($class, $name, $args, $col) = @_;
    sub { $col->{transport_args} };
}

sub _build_riak_transport {
    my ($class, $name, $args, $col) = @_;
    sub { $col->{transport} };
}

sub _build_skip_unless_riak {
    my ($class, $name, $args, $col) = @_;
    sub { skip_unless_riak($col->{transport}, @_) };
}

sub _build_skip_unless_leveldb_backend {
    my ($class, $name, $args, $col) = @_;
    sub { skip_unless_leveldb_backend($col->{transport}, @_) };
}

my $import = Sub::Exporter::build_exporter({
    exports    => [
        riak_transport_args         => \&_build_riak_transport_args,
        riak_transport              => \&_build_riak_transport,
        remove_test_bucket          => sub { \&remove_test_bucket },
        create_test_bucket_name     => sub { \&create_test_bucket_name },
        skip_unless_riak            => \&_build_skip_unless_riak,
        skip_unless_leveldb_backend => \&_build_skip_unless_leveldb_backend,
    ],
    groups     => {
        default => [qw(riak_transport riak_transport_args remove_test_bucket
                       create_test_bucket_name skip_unless_riak
                       skip_unless_leveldb_backend)],
    },
    collectors => ['transport', 'transport_args'],
    into_level => 1,
});

sub import {
    my ($class, @args) = @_;
    my $transport_args = ref $args[0] eq 'HASH' ? shift @args : {};
    my ($computed_transport_args, $transport) = _build_transport($transport_args);
    $import->($class,
              transport      => $transport,
              transport_args => $computed_transport_args,
              @args ? @args : '-default');
}

sub create_test_bucket_name {
	my $prefix = shift || 'data-riak-test';
    return sprintf '%s-%s-%s', $prefix, $$, md5_hex(scalar localtime);
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
            $bucket->remove_all;
            sleep(1);
            $keys = $bucket->list_keys;
        }
    } catch {
        isa_ok $_, 'Data::Riak::Exception';
    };
}

