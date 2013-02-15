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
                return $cb->($request->_mangle_retval($results[0]));
            }

            $cb->($request->_mangle_retval(
                Data::Riak::ResultSet->new({ results => \@results }),
            ));
        },
        $request->error_cb,
    );

    return;
}

sub ping {
    my ($self, $opts) = @_;

    $self->send_request({
        %{ $opts },
        type => 'Ping',
    });

    return;
}

sub status {
    my ($self, $opts) = @_;

    $self->send_request({
        %{ $opts },
        type => 'Status',
    });

    return;
}

sub _buckets {
    my ($self, $opts) = @_;

    $self->send_request({
        %{ $opts },
        type => 'ListBuckets',
    });

    return;
}

sub resolve_link {
    my ($self, $link, $opts) = @_;
    $self->bucket( $link->bucket )->get($link->key => $opts);
}

sub linkwalk {
    my ($self, $args) = @_;
    my $object = delete $args->{object} || confess 'You must have an object to linkwalk';
    my $bucket = delete $args->{bucket} || confess 'You must have a bucket for the original object to linkwalk';

    $self->send_request({
        %{ $args },
        type        => 'LinkWalk',
        bucket_name => $bucket,
        key         => $object,
    });

    return;
}

__PACKAGE__->meta->make_immutable;

1;
