package Data::Riak::Async::Bucket;

use Moose;
use JSON 'decode_json';
use Data::Riak::Async::MapReduce;
use namespace::autoclean;

with 'Data::Riak::Role::HasRiak',
     'Data::Riak::Role::Bucket';

sub add {
    my ($self, $key, $value, $opts) = @_;

    confess 'you need to provide a callback'
        if !$opts || !exists $opts->{cb};
    confess 'you need to provide an error callback'
        if !$opts || !exists $opts->{error_cb};

    my $pack = $self->_build_linklist($opts->{links});

    $self->riak->send_request({
        cb          => $opts->{cb},
        error_cb    => $opts->{error_cb},
        type        => 'StoreObject',
        bucket_name => $self->name,
        key         => $key,
        value       => $value,
        links       => $pack,
        return_body => $opts->{return_body},
        (exists $opts->{content_type}
             ? (content_type => $opts->{content_type}) : ()),
        (exists $opts->{indexes}
             ? (indexes => $opts->{indexes}) : ()),
        (exists $opts->{vector_clock}
             ? (vector_clock => $opts->{vector_clock}) : ()),
        (exists $opts->{if_unmodified_since}
             ? (if_unmodified_since => $opts->{if_unmodified_since}) : ()),
        (exists $opts->{if_match}
             ? (if_match => $opts->{if_match}) : ()),
    });

    return;
}

sub remove {
    my ($self, $key, $opts) = @_;

    confess 'you need to provide a callback'
        if !$opts || !exists $opts->{cb};

    confess 'you need to provide an error callback'
        if !$opts || !exists $opts->{error_cb};

    $self->riak->send_request({
        type        => 'RemoveObject',
        bucket_name => $self->name,
        key         => $key,
        cb          => $opts->{cb},
        error_cb    => $opts->{error_cb},
    });

    return;
}

sub get {
    my ($self, $key, $opts) = @_;

    confess "This method requires a key" unless $key;

    confess 'you need to provide a callback'
        if !$opts || !exists $opts->{cb};

    confess 'you need to provide an error callback'
        if !$opts || !exists $opts->{error_cb};

    confess "This method does not support multipart/mixed responses"
        if exists $opts->{'accept'} && $opts->{'accept'} eq 'multipart/mixed';

    $self->riak->send_request({
        %{ $opts },
        type        => 'GetObject',
        bucket_name => $self->name,
        key         => $key,
    });

    return;
}

sub list_keys {
    my ($self, $cb, $error_cb) = @_;

    $self->riak->send_request({
        type        => 'ListBucketKeys',
        bucket_name => $self->name,
        cb          => $cb,
        error_cb    => $error_cb,
    });

    return;
}

sub count {
    my ($self, $cb, $error_cb) = @_;

    my $map_reduce = Data::Riak::Async::MapReduce->new({
        riak   => $self->riak,
        inputs => $self->name,
        phases => [
            Data::Riak::Util::MapCount->new,
            Data::Riak::Util::ReduceCount->new
        ],
    });

    $map_reduce->mapreduce(
        cb             => $cb,
        error_cb       => $error_cb,
        retval_mangler => sub {
            my ($map_reduce_results) = @_;
            my ($result) = $map_reduce_results->results->[0];
            my ($count) = decode_json($result->value) || 0;
            return $count->[0];
        },
    );

    return;
}

sub remove_all {
    my ($self, $cb, $error_cb) = @_;

    $self->list_keys(sub {
        my ($keys) = @_;
        return $cb->() unless ref $keys eq 'ARRAY' && @$keys;

        my %keys = map { ($_ => 1) } @{ $keys };
        for my $key (@{ $keys }) {
            $self->remove($key, {
                cb => sub {
                    delete $keys{$key};
                    $cb->() if !keys %keys;
                },
                error_cb => $error_cb,
            });
        }
    }, $error_cb);

    return;
}

sub linkwalk {
    my ($self, $object, $params, $cb, $error_cb) = @_;
    return undef unless $params;

    $self->riak->linkwalk({
        bucket   => $self->name,
        object   => $object,
        params   => $params,
        cb       => $cb,
        error_cb => $error_cb,
    });

    return;
}

sub search_index {
    my ($self, $opts) = @_;
    my $field    = $opts->{'field'}  || confess 'You must specify a field for searching Secondary indexes';
    my $values   = $opts->{'values'} || confess 'You must specify values for searching Secondary indexes';
    my $cb       = $opts->{cb} || confess 'You must provide a callback to linkwalk';
    my $error_cb = $opts->{cb} || confess 'You must provide an error callback to linkwalk';

    my $inputs = { bucket => $self->name, index => $field };
    if(ref($values) eq 'ARRAY') {
        $inputs->{'start'} = $values->[0];
        $inputs->{'end'} = $values->[1];
    } else {
        $inputs->{'key'} = $values;
    }

    my $search_mr = Data::Riak::Async::MapReduce->new({
        riak => $self->riak,
        inputs => $inputs,
        phases => [
            Data::Riak::MapReduce::Phase::Reduce->new({
                language => 'erlang',
                module => 'riak_kv_mapreduce',
                function => 'reduce_identity',
                keep => 1
            })
        ]
    });

    $search_mr->mapreduce(
        cb       => sub { $cb->(shift->results->[0]->value) },
        error_cb => $error_cb,
    );

    return;
}

sub pretty_search_index {
    my ($self, $opts) = @_;

    my $cb = delete $opts->{cb};

    $self->search_index({
        %{ $opts },
        cb => sub {
            $cb->([sort map { $_->[1] } @{ decode_json shift }]);
        },
    });
}

sub props {
    my ($self, $cb, $error_cb) = @_;

    $self->riak->send_request({
        type        => 'GetBucketProps',
        bucket_name => $self->name,
        cb          => $cb,
        error_cb    => $error_cb,
    });

    return;
}

sub set_props {
    my ($self, $props, $cb, $error_cb) = @_;

    $self->riak->send_request({
        type        => 'SetBucketProps',
        bucket_name => $self->name,
        props       => $props,
        cb          => $cb,
        error_cb    => $error_cb,
    });

    return;
}

sub create_alias {
    my ($self, $opts) = @_;
    my $bucket = $opts->{in} || $self;

    $bucket->add(
        $opts->{as}, $opts->{key},
        {
            links => [
                Data::Riak::Link->new(
                    bucket => $bucket->name,
                    riaktag => 'perl-data-riak-alias',
                    key => $opts->{key},
                ),
            ],
            cb       => $opts->{cb},
            error_cb => $opts->{error_cb},
        },
    );

    return;
}

sub resolve_alias {
    my ($self, $alias, $cb, $error_cb) = @_;

    $self->linkwalk(
        $alias, [[ 'perl-data-riak-alias', '_' ]],
        sub { $cb->(shift->first) }, $error_cb,
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;
