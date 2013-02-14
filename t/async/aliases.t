use strict;
use warnings;
use Test::More 0.89;

use Test::Data::Riak;

BEGIN {
    skip_unless_riak;
}

use Try::Tiny;
use AnyEvent;
use Data::Riak::Async;
use Data::Riak::Async::HTTP;

my $riak = Data::Riak::Async->new({
    transport => Data::Riak::Async::HTTP->new(riak_transport_args),
});

my $bucket_name = create_test_bucket_name;
my $bucket_name2 = create_test_bucket_name;

my $bucket = Data::Riak::Async::Bucket->new({
    name => $bucket_name,
    riak => $riak,
});

my $bucket2 = Data::Riak::Async::Bucket->new({
    name => $bucket_name2,
    riak => $riak,
});

{
    my @cvs;
    my $get_cbs = sub {
        my $cv = AE::cv;
        push @cvs, $cv;
        (sub { $cv->send(@_) }, sub { $cv->croak(@_) });
    };

    $_->count($get_cbs->()) for $bucket, $bucket2;
    is $_, 0, 'No keys in the bucket'
        for map { $_->recv } @cvs;
}

my $foo_user_data = '{"username":"foo","email":"foo@example.com"';

{
    my $cv = AE::cv;
    $bucket->add('123456', $foo_user_data, {
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });
    $cv->recv;
}

{
    my @cvs;
    my $get_cbs = sub {
        my $cv = AE::cv;
        push @cvs, $cv;
        (cb => sub { $cv->send(@_) }, error_cb => sub { $cv->croak(@_) });
    };

    $bucket->create_alias({
        key => '123456',
        as  => 'foo',
        $get_cbs->(),
    });

    $bucket->create_alias({
        key => '123456',
        as  => 'foo',
        in  => $bucket2,
        $get_cbs->(),
    });

    $_->recv for @cvs;
}

{
    my $cv = AE::cv;
    $bucket->get('123456', {
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    my @cvs;
    my $get_cbs = sub {
        my $cv = AE::cv;
        push @cvs, $cv;
        (sub { $cv->send(@_) }, sub { $cv->croak(@_) });
    };

    $bucket->resolve_alias('foo', $get_cbs->());
    $bucket2->resolve_alias('foo', $get_cbs->());

    my ($obj, $resolved_obj, $resolved_across_buckets_obj) =
        map { $_->recv } $cv, @cvs;

    is $obj->value, $foo_user_data, "Calling for foo's data by ID works";
    is $resolved_obj->value, $foo_user_data,
        "Calling for foo's data by alias works";
    is $resolved_across_buckets_obj->value, $foo_user_data,
        "Calling for foo's data by a cross-bucket alias works";

}

sub remove_async_test_bucket {
    my ($bucket, $cb, $error_cb) = @_;

    my ($remove_all_and_wait, $t);
    $remove_all_and_wait = sub {
        $bucket->remove_all(
            sub {
                $t = AE::timer 1, 0, sub {
                    $bucket->list_keys(
                        sub {
                            my ($keys) = @_;

                            if ($keys && @{ $keys }) {
                                $remove_all_and_wait->();
                                return;
                            }

                            $cb->();
                        },
                        $error_cb,
                    );
                },
            },
            $error_cb,
        );
    };

    $remove_all_and_wait->();
}

{
    my ($cv, $cv2) = map { AE::cv } 0, 1;

    diag 'Removing test bucket so sleeping for a moment to allow riak to eventually be consistent ...'
        if $ENV{HARNESS_IS_VERBOSE};

    remove_async_test_bucket($bucket, sub { $cv->send }, sub { $cv->croak(@_) });
    remove_async_test_bucket($bucket2, sub { $cv2->send }, sub { $cv2->croak(@_) });

    try {
        $cv->recv; $cv2->recv;
    } catch {
        isa_ok $_, 'Data::Riak::Exception';
    };
}

done_testing;
