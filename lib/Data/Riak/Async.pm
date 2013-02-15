package Data::Riak::Async;

use Moose;
use Data::Riak::Async::HTTP;
use Data::Riak::Async::Bucket;
use namespace::autoclean;

with 'Data::Riak::Role::Frontend';

# FIXME: factor out stuff til ping

has transport => (
    is       => 'ro',
    isa      => 'Data::Riak::Async::HTTP',
    required => 1,
    handles  => {
        'base_uri' => 'base_uri'
    }
);

sub _build_request_classes {
    return +{
        (map {
            ($_ => 'Data::Riak::Async::Request::' . $_),
        } qw(MapReduce Ping GetBucketProps StoreObject GetObject
             ListBucketKeys RemoveObject LinkWalk Status ListBuckets
             SetBucketProps)),
    }
}

sub _build_bucket_class { 'Data::Riak::Async::Bucket' }

sub send_request {
    my ($self, $request_data) = @_;

    my $request = $self->_create_request($request_data);

    my $cb = $request->cb;
    $self->transport->send(
        $request,
        sub {
            my ($response) = @_;

            my @results = $response->create_results($self, $request);
            return $cb->(undef) unless @results;

            if (@results == 1 && $results[0]->does('Data::Riak::Result::Single')) {
                return $cb->($results[0]);
            }

            $cb->(Data::Riak::ResultSet->new({ results => \@results }));
        },
        $request->error_cb,
    );

    return;
}

sub ping {
    my ($self, $cb, $error_cb) = @_;

    $self->send_request({
        type     => 'Ping',
        cb       => sub { $cb->(shift->status_code == 200 ? 1 : 0) },
        error_cb => $error_cb,
    });

    return;
}

sub status {
    my ($self, $cb, $error_cb) = @_;

    $self->send_request({
        type     => 'Status',
        cb       => sub { $cb->(shift->json_value) },
        error_cb => $error_cb,
    });

    return;
}

sub _buckets {
    my ($self, $cb, $error_cb) = @_;

    $self->send_request({
        type     => 'ListBuckets',
        cb       => sub { $cb->(shift->json_value->{buckets}) },
        error_cb => $error_cb,
    });

    return;
}

sub resolve_link {
    my ($self, $link, $cb, $error_cb) = @_;
    $self->bucket( $link->bucket )->get($link->key => {
        cb       => $cb,
        error_cb => $error_cb,
    });
}


sub linkwalk {
    my ($self, $args) = @_;
    my $object   = $args->{object} || confess 'You must have an object to linkwalk';
    my $bucket   = $args->{bucket} || confess 'You must have a bucket for the original object to linkwalk';
    my $cb       = $args->{cb} || confess 'You must provide a callback to linkwalk';
    my $error_cb = $args->{error_cb} || confess 'You must provide an error callback to linkwalk';

    $self->send_request({
        type        => 'LinkWalk',
        bucket_name => $bucket,
        key         => $object,
        params      => $args->{params},
        cb          => $cb,
        error_cb    => $error_cb,
    });

    return;
}

__PACKAGE__->meta->make_immutable;

1;
