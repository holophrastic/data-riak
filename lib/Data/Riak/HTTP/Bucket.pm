package Data::Riak::HTTP::Bucket;

use strict;
use warnings;

use HTTP::Headers::ActionPack;
use HTTP::Headers::ActionPack::Link;
use HTTP::Headers::ActionPack::LinkList;

use URL::Encode qw/url_encode/;

use Moose;

has riak => (
    is => 'ro',
    isa => 'Data::Riak::HTTP',
    required => 1
);

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

sub add {
    my ($self, $key, $value, $links) = @_;

    my $pack = HTTP::Headers::ActionPack::LinkList->new;
    if($links) {
        foreach my $link (@{$links}) {
            if(blessed $link && $link->isa('HTTP::Headers::ActionPack::Link')) {
                $pack->add($link);
            } else {
                my $link_url = $link->{url} || sprintf('/buckets/%s/keys/%s', $link->{bucket} || $self->name, $link->{target});
                my $created_link = HTTP::Headers::ActionPack::Link->new(
                    $link_url => (
                        riaktag => url_encode($link->{type})
                    )
                );
                $pack->add($created_link);
            }
        }
    }

    my $request = Data::Riak::HTTP::Request->new({
        method => 'PUT',
        uri => sprintf('buckets/%s/keys/%s', $self->name, $key),
        data => $value,
        links => $pack
    });
    return $self->riak->send($request);
}

sub remove {
    my ($self, $key) = @_;
    my $request = Data::Riak::HTTP::Request->new({
        method => 'DELETE',
        uri => sprintf('buckets/%s/keys/%s', $self->name, $key)
    });
    return $self->riak->send($request);
}

sub get {
    my ($self, $key) = @_;
    my $request = Data::Riak::HTTP::Request->new({
        method => 'GET',
        uri => sprintf('buckets/%s/keys/%s', $self->name, $key)
    });
    my $response = $self->riak->send($request);
    if($response->is_error) {
        # don't just die here; return the busted object and let the caller handle it
        return Data::Riak::HTTP::Result->new({
            riak => $self->riak,
            http_message => $response->http_response
        });
    }
    return $response->result;
}

sub list_keys {
    my $self = shift;
    my $request = Data::Riak::HTTP::Request->new({
        method => 'GET',
        uri => sprintf('buckets/%s/keys?keys=true', $self->name)
    });

    my $response = $self->riak->send($request);
    if($response->is_error) {
        # don't just die here; return the busted object and let the caller handle it
        return Data::Riak::HTTP::Result->new({
            riak => $self->riak,
            http_message => $response->http_response
        });
    }
    return $response->result;
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

    my $request = Data::Riak::HTTP::Request->new({
        method => 'GET',
        uri => $self->name
    });

    return $self->riak->send($request);
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

    my $request = Data::Riak::HTTP::Request->new({
        method => 'PUT',
        content_type => 'application/json',
        uri => $self->name,
        data => $data
    });

    return $self->riak->send($request);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
