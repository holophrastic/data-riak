package Data::Riak::Bucket;

use strict;
use warnings;

use Moose;

use Data::Riak::Link;
use Data::Riak::Util::MapCount;
use Data::Riak::Util::ReduceCount;
use HTTP::Headers::ActionPack::LinkList;

use JSON::XS qw/decode_json encode_json/;

with 'Data::Riak::Role::HasRiak';

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

sub add {
    my ($self, $key, $value, $opts) = @_;

    $opts ||= {};

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

    # TODO:
    # need to support other headers
    #   X-Riak-Vclock if the object already exists, the vector clock attached to the object when read.
    #   X-Riak-Meta-* - any additional metadata headers that should be stored with the object.
    #   X-Riak-Index-* - index entries under which this object should be indexed. Read more about Secondary Indexing.
    # see http://wiki.basho.com/HTTP-Store-Object.html
    # - SL

    my $resultset = $self->riak->send_request({
        method => 'PUT',
        uri => sprintf('buckets/%s/keys/%s', $self->name, $key),
        data => $value,
        links => $pack,
        (exists $opts->{'content_type'}
            ? (content_type => $opts->{'content_type'})
            : ()),
        (exists $opts->{'query'}
            ? (query => $opts->{'query'})
            : ()),
    });

    return $resultset->first if $resultset;
    return;
}

sub remove {
    my ($self, $key, $opts) = @_;

    $opts ||= {};

    return $self->riak->send_request({
        method => 'DELETE',
        uri => sprintf('buckets/%s/keys/%s', $self->name, $key),
        (exists $opts->{'query'}
            ? (query => $opts->{'query'})
            : ()),
    });
}

sub get {
    my ($self, $key, $opts) = @_;

    die("This method requires a key") unless($key);

    $opts ||= {};

    confess "This method does not support multipart/mixed responses"
        if exists $opts->{'accept'} && $opts->{'accept'} eq 'multipart/mixed';

    return $self->riak->send_request({
        method => 'GET',
        uri => sprintf('buckets/%s/keys/%s', $self->name, $key),
        (exists $opts->{'accept'}
            ? (accept => $opts->{'accept'})
            : ()),
        (exists $opts->{'query'}
            ? (query => $opts->{'query'})
            : ()),
    })->first;
}

sub list_keys {
    my $self = shift;

    my $result = $self->riak->send_request({
        method => 'GET',
        uri => sprintf('buckets/%s/keys', $self->name),
        query => { keys => 'true' }
    })->first;

    return decode_json( $result->value )->{'keys'};
}

sub count {
    my $self = shift;
    my $map_reduce = Data::Riak::MapReduce->new({
        riak => $self->riak,
        inputs => $self->name,
        phases => [
            Data::Riak::Util::MapCount->new,
            Data::Riak::Util::ReduceCount->new
        ]
    });
    my $map_reduce_results = $map_reduce->mapreduce;
    my ( $result ) = $map_reduce_results->results->[0];
    my ( $count ) = decode_json($result->value) || 0;
    return $count->[0];
}

sub remove_all {
    my $self = shift;
    my $keys = $self->list_keys;
    return unless ref $keys eq 'ARRAY' && @$keys;
    foreach my $key ( @$keys ) {
        $self->remove( $key );
    }
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

sub linkwalk {
    my ($self, $object, $params) = @_;
    return undef unless $params;
    return $self->riak->linkwalk({
        bucket => $self->name,
        object => $object,
        params => $params
    });
}

sub props {
    my $self = shift;

    my $result = $self->riak->send_request({
        method => 'GET',
        uri => sprintf('buckets/%s/props', $self->name)
    })->first;

    return decode_json( $result->value )->{'props'};
}

sub indexing {
    my ($self, $enable) = @_;

    my $data;

    if($enable) {
        $data->{props}->{precommit}->{mod} = 'riak_search_kv_hook';
        $data->{props}->{precommit}->{fun} = 'precommit';
    } else {
        $data->{props}->{precommit}->{mod} = undef;
        $data->{props}->{precommit}->{fun} = undef;
    };

    return $self->riak->send_request({
        method => 'PUT',
        content_type => 'application/json',
        uri => $self->name,
        data => encode_json($data)
    });
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
