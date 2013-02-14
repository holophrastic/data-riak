package Data::Riak::Async;

use Moose;
use Data::Riak::Async::HTTP;
use Class::Load 'load_class';
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

has request_classes => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[Str]',
    builder => '_build_request_classes',
    handles => {
        _available_request_classes => 'values',
        request_class_for          => 'get',
        has_request_class_for      => 'exists',
    },
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

sub BUILD {
    my ($self) = @_;

    load_class $_
        for $self->_available_request_classes;
}

sub _create_request {
    my ($self, $args) = @_;

    my %args_copy = %{ $args };
    my $type = delete $args_copy{type};

    confess sprintf 'Unknown request class %s', $type
        unless $self->has_request_class_for($type);

    return $self->request_class_for($type)->new(\%args_copy);
}

sub send_request {
    my ($self, $request_data) = @_;

    my $request = $self->_create_request($request_data);

    my $cb = $request->cb;
    $self->transport->send($request, sub {
        my ($response) = @_;

        my @results = $response->create_results($self, $request);
        return $cb->(undef) unless @results;

        if (@results == 1 && $results[0]->does('Data::Riak::Result::Single')) {
            return $cb->($results[0]);
        }

        $cb->(Data::Riak::ResultSet->new({ results => \@results }));
    });

    return;
}

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
