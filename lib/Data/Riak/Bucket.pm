package Data::Riak::Bucket;

use strict;
use warnings;

use HTTP::Headers::ActionPack;
use HTTP::Headers::ActionPack::LinkHeader;
use HTTP::Headers::ActionPack::LinkList;

use URL::Encode qw/url_encode/;
use JSON::XS qw/decode_json encode_json/;

use Moose;

has riak => (
    is => 'ro',
    isa => 'Data::Riak',
    required => 1
);

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
            if(blessed $link && $link->isa('HTTP::Headers::ActionPack::LinkHeader')) {
                $pack->add($link);
            } else {
                my $link_url = $link->{url} || sprintf('/buckets/%s/keys/%s', $link->{bucket} || $self->name, $link->{target});
                my $created_link = HTTP::Headers::ActionPack::LinkHeader->new(
                    $link_url => (
                        # NOTE:
                        # we do the inverse of this in
                        # &Data::Riak::Result::link
                        # - SL
                        riaktag => url_encode($link->{type})
                    )
                );
                $pack->add($created_link);
            }
        }
    }

    return $self->riak->send_request({
        method => 'PUT',
        uri => sprintf('buckets/%s/keys/%s', $self->name, $key),
        data => $value,
        links => $pack,
        (exists $opts->{'content_type'}
            ? (content_type => $opts->{'content_type'})
            : ())
    });
}

sub remove {
    my ($self, $key) = @_;
    return $self->riak->send_request({
        method => 'DELETE',
        uri => sprintf('buckets/%s/keys/%s', $self->name, $key)
    });
}

sub get {
    my ($self, $key, $opts) = @_;

    $opts ||= {};

    my $resultset = $self->riak->send_request({
        method => 'GET',
        uri => sprintf('buckets/%s/keys/%s', $self->name, $key),
        (exists $opts->{'accept'}
            ? (accept => $opts->{'accept'})
            : ())
    });
}

sub list_keys {
    my $self = shift;

    my $result = $self->riak->send_request({
        method => 'GET',
        uri => sprintf('buckets/%s/keys?keys=true', $self->name)
    })->first;

    return decode_json( $result->value )->{'keys'};
}

sub remove_all {
    my $self = shift;
    my $keys = $self->list_keys;
    return unless ref $keys eq 'ARRAY' && @$keys;
    foreach my $key ( @$keys ) {
        $self->remove( $key );
    }
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

    return $self->riak->send_request({
        method => 'GET',
        uri => $self->name
    })->first;
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
