package Data::Riak::Role::Bucket;

use Moose::Role;
use JSON 'decode_json';
use Data::Riak::Link;
use HTTP::Headers::ActionPack::LinkList;
use namespace::autoclean;

with 'Data::Riak::Role::HasRiak';

sub new_mapreduce { shift->riak->new_mapreduce(@_) }

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_linklist {
    my ($self, $links) = @_;

    my $pack = HTTP::Headers::ActionPack::LinkList->new;

    for my $link (@{ $links || [] }) {
        if(blessed $link && $link->isa('Data::Riak::Link')) {
            $pack->add($link->as_link_header);
        }
        else {
            confess "Bad link type ($link)";
        }
    }

    return $pack;
}

sub create_link {
    my $self = shift;
    my %opts = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    confess "You must provide a key for a link" unless exists $opts{key};
    confess "You must provide a riaktag for a link" unless exists $opts{riaktag};
    return Data::Riak::Link->new({
        bucket => $self->name,
        key => $opts{key},
        riaktag => $opts{riaktag},
        (exists $opts{params} ? (params => $opts{params}) : ())
    });
}

sub add {
    my ($self, $key, $value, $opts) = @_;

    my $pack = $self->_build_linklist($opts->{links});

    # TODO:
    # need to support other headers
    #   X-Riak-Vclock if the object already exists, the vector clock attached to the object when read.
    #   X-Riak-Meta-* - any additional metadata headers that should be stored with the object.
    # see http://wiki.basho.com/HTTP-Store-Object.html
    # - SL

    return $self->riak->send_request({
        %{ $opts || {} },
        type        => 'StoreObject',
        bucket_name => $self->name,
        key         => $key,
        value       => $value,
        links       => $pack,
    });
}

sub remove {
    my ($self, $key, $opts) = @_;

    return $self->riak->send_request({
        %{ $opts || {} },
        type        => 'RemoveObject',
        bucket_name => $self->name,
        key         => $key,
    });
}

sub get {
    my ($self, $key, $opts) = @_;

    confess "This method requires a key" unless $key;

    $opts ||= {};

    confess "This method does not support multipart/mixed responses"
        if exists $opts->{'accept'} && $opts->{'accept'} eq 'multipart/mixed';

    return $self->riak->send_request({
        %{ $opts },
        type        => 'GetObject',
        bucket_name => $self->name,
        key         => $key,
    });
}
sub list_keys {
    my ($self, $opts) = @_;

    return $self->riak->send_request({
        %{ $opts || {} },
        type        => 'ListBucketKeys',
        bucket_name => $self->name,
    });
}

sub count {
    my ($self, $opts) = @_;

    my $map_reduce = $self->new_mapreduce({
        riak   => $self->riak,
        inputs => $self->name,
        phases => [
            Data::Riak::Util::MapCount->new,
            Data::Riak::Util::ReduceCount->new,
        ],
    });

    return $map_reduce->mapreduce(
        %{ $opts || {} },
        retval_mangler => sub {
            my ($map_reduce_results) = @_;
            my ($result) = $map_reduce_results->results->[0];
            my ($count) = decode_json($result->value) || 0;
            return $count->[0];
        },
    );
}

sub linkwalk {
    my ($self, $object, $params, $opts) = @_;
    return undef unless $params; # TODO: needs to go. breaks async

    return $self->riak->linkwalk({
        %{ $opts || {} },
        bucket => $self->name,
        object => $object,
        params => $params,
    });
}

sub props {
    my ($self, $opts) = @_;

    return $self->riak->send_request({
        %{ $opts || {} },
        type        => 'GetBucketProps',
        bucket_name => $self->name,
    });
}

sub set_props {
    my ($self, $props, $opts) = @_;

    return $self->riak->send_request({
        %{ $opts || {} },
        type        => 'SetBucketProps',
        bucket_name => $self->name,
        props       => $props,
    });
}

sub create_alias {
    my ($self, $opts) = @_;
    my $bucket = delete $opts->{in} || $self;

    return $bucket->add($opts->{as}, $opts->{key}, {
        %{ $opts },
        links => [
            Data::Riak::Link->new(
                bucket => $bucket->name,
                riaktag => 'perl-data-riak-alias',
                key => $opts->{key},
            ),
        ],
    });
}

sub resolve_alias {
    my ($self, $alias, $opts) = @_;

    return $self->linkwalk($alias, [[ 'perl-data-riak-alias', '_' ]], {
        %{ $opts || {} },
        retval_mangler => sub { shift->first },
    });
}

1;
