package Data::Riak::HTTP::Bucket;

use strict;
use warnings;

use HTTP::Headers::ActionPack;
use HTTP::Headers::ActionPack::Link;
use HTTP::Headers::ActionPack::LinkList;

use Scalar::Util qw/blessed/;

use Moose;

has riak => (
    is => 'ro',
    isa => 'Data::Riak::HTTP',
    default => sub { {
        return Data::Riak::HTTP->new;
    } }
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
                my $link_url = $link->{url} || sprintf('</riak/%s/%s>', $link->{bucket} || $self->name, $link->{target});
                #use Data::Dump;
               # ddx($link);
               my $type = $link->{type};
               $type =~ s/ /%20/g;
                my $created_link = HTTP::Headers::ActionPack::Link->new($link_url => (
                    # this is dumb
                    riaktag =>  sprintf('###%s###', $type)
                ));
                
               #my $created_link = HTTP::Headers::ActionPack::Link->new_from_string(
               #    sprintf('%s; riaktag="%s"', $link_url, $type)
               #);
                #ddx($created_link);
               # ddx($created_link->to_string);
                $pack->add($created_link);
            }
        }
    }

    my $request = Data::Riak::HTTP::Request->new({
        method => 'PUT',
        uri => sprintf('%s/%s', $self->name, $key),
        data => $value,
        links => $pack
    });
    return $self->riak->send($request);
}

sub remove {
    my ($self, $key) = @_;
    my $request = Data::Riak::HTTP::Request->new({
        method => 'DELETE',
        uri => sprintf('%s/%s', $self->name, $key)
    });
    return $self->riak->send($request);
}

sub get {
    my ($self, $key) = @_;
    my $request = Data::Riak::HTTP::Request->new({
        method => 'GET',
        uri => sprintf('%s/%s', $self->name, $key)
    });
    my $response = $self->riak->send($request);
    if($response->is_error) {
        # don't just die here; return the busted object and let the caller handle it
        return Data::Riak::HTTP::Result->new({ http_message => $response->http_response });
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

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
