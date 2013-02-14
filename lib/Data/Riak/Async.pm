package Data::Riak::Async;

use Moose;
use namespace::autoclean;

sub ping {
    my ($self, $cb) = @_;

    $self->send_request({
        type => 'Ping',
        cb   => sub {
            my ($resp) = @_;
            $cb->($resp->status_code == 200 ? 1 : 0);
        },
    });

    return;
}

sub status {
    my ($self, $cb) = @_;

    $self->send_request({
        type => 'Status',
        cb   => sub { $cb->(shift->json_value) },
    });

    return;
}

sub _buckets {
    my ($self, $cb) = @_;

    $self->send_request({
        type => 'ListBuckets',
        cb   => sub { $cb->(shift->json_value->{buckets}) },
    });

    return;
}

sub linkwalk {
    my ($self, $args) = @_;
    my $object = $args->{object} || confess 'You must have an object to linkwalk';
    my $bucket = $args->{bucket} || confess 'You must have a bucket for the original object to linkwalk';
    my $cb     = $args->{cb} || confess 'You must provide a callback to linkwalk';

    $self->send_request({
        type        => 'LinkWalk',
        bucket_name => $bucket,
        key         => $object,
        params      => $args->{params},
        cb          => $cb,
    });

    return;
}

__PACKAGE__->meta->make_immutable;

1;
