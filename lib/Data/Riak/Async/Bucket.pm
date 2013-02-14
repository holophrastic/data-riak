package Data::Riak::Async::Bucket;

use Moose;
use namespace::autoclean;

sub add {
    my ($self, $key, $value, $opts) = @_;

    confess 'you need to provide a callback'
        if !$opts || !exists $opts->{cb};

    # FIXME: factor out and reuse from Bucket
    my $pack = HTTP::Headers::ActionPack::LinkList->new;
    if($opts->{'links'}) {
        foreach my $link (@{$opts->{'links'}}) {
            if(blessed $link && $link->isa('Data::Riak::Link')) {
                $pack->add($link->as_link_header);
            }
            else {
                confess "Bad link type ($link)";
            }
        }
    }

    $self->riak->send_request({
        cb          => $opts->{cb},
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

    $self->riak->send_request({
        type        => 'RemoveObject',
        bucket_name => $self->name,
        key         => $key,
        cb          => $opts->{cb},
    });

    return;
}

sub get {
    my ($self, $key, $opts) = @_;

    confess "This method requires a key" unless $key;

    confess 'you need to provide a callback'
        if !$opts || !exists $opts->{cb};

    confess "This method does not support multipart/mixed responses"
        if exists $opts->{'accept'} && $opts->{'accept'} eq 'multipart/mixed';

    $self->riak->send_request({
        type        => 'GetObject',
        bucket_name => $self->name,
        key         => $key,
        cb          => $opts->{cb},
    });

    return;
}

sub list_keys {
    my ($self, $cb) = @_;

    $self->riak->send_request({
        type        => 'ListBucketKeys',
        bucket_name => $self->name,
        cb          => sub { $cb->(shift->json_value->{keys}) },
    });

    return;
}

sub count {
    my ($self, $cb) = @_;

    my $map_reduce = Data::Riak::Async::MapReduce->new({
        riak   => $self->riak,
        inputs => $self->name,
        phases => [
            Data::Riak::Util::MapCount->new,
            Data::Riak::Util::ReduceCount->new
        ],
    });

    $map_reduce->mapreduce(cb => sub {
        my ($map_reduce_results) = @_;
        my ($result) = $map_reduce_results->results->[0];
        my ($count) = decode_json($result->value) || 0;
        $cb->($count->[0]);
    });

    return;
}

sub remove_all {
    my ($self, $cb) = @_;

    $self->list_keys(sub {
        my ($keys) = @_;
        return $cb->() unless ref $keys eq 'ARRAY' && @$keys;

        my %keys = map { ($_ => 1) } @{ $keys };
        for my $key (@{ $keys }) {
            $self->remove($key, {
                cb => sub {
                    delete $keys->{$key};
                    $cb->() if !keys %keys;
                },
            });
        }
    });

    return;
}

sub linkwalk {
    my ($self, $object, $params, $cb) = @_;
    return undef unless $params;

    $self->riak->linkwalk({
        bucket => $self->name,
        object => $object,
        params => $params,
        cb     => $cb,
    });

    return;
}

sub search_index {
    my ($self, $opts) = @_;
    my $field  = $opts->{'field'}  || confess 'You must specify a field for searching Secondary indexes';
    my $values = $opts->{'values'} || confess 'You must specify values for searching Secondary indexes';
    my $cb     = $opts->{cb} || confess 'You must provide a callback to linkwalk';

    my $inputs = { bucket => $self->name, index => $field };
    if(ref($values) eq 'ARRAY') {
        $inputs->{'start'} = $values->[0];
        $inputs->{'end'} = $values->[1];
    } else {
        $inputs->{'key'} = $values;
    }

    my $search_mr = Data::Riak::MapReduce->new({
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

    $search_mr->mapreduce(cb => sub {
        $cb->(shift->results->[0]->value);
    });

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
    my ($self, $cb) = @_;

    $self->riak->send_request({
        type        => 'GetBucketProps',
        bucket_name => $self->name,
        cb          => sub { $cb->(shift->json_value->{props}) },
    });

    return;
}

sub set_props {
    my ($self, $props, $cb) = @_;

    $self->riak->send_request({
        type        => 'SetBucketProps',
        bucket_name => $self->name,
        props       => $props,
        cb          => $cb,
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
            cb => $opts->{cb},
        },
    );

    return;
}

sub resolve_alias {
    my ($self, $alias, $cb) = @_;

    $self->linkwalk($alias, [[ 'perl-data-riak-alias', '_' ]], sub {
        $cb->(shift->first);
    });

    return;
}

__PACKAGE__->meta->make_immutable;

1;
