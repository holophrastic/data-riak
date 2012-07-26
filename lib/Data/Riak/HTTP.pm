package Data::Riak::HTTP;
# ABSTRACT: An interface to a Riak server, using its HTTP (REST) interface

use strict;
use warnings;

use Moose;

use LWP;
use HTTP::Headers;
use HTTP::Response;
use HTTP::Request;

use Data::Riak::HTTP::Request;
use Data::Riak::HTTP::Response;

=attr host

The host the Riak server is on. Can be set via the environment variable
DATA_RIAK_HTTP_HOST, and defaults to 127.0.0.1.

=cut

has host => (
    is => 'ro',
    isa => 'Str',
    default => sub {
        $ENV{'DATA_RIAK_HTTP_HOST'} || '127.0.0.1';
    }
);

=attr port

The port of the host that the riak server is on. Can be set via the environment
variable DATA_RIAK_HTTP_PORT, and defaults to 8098.

=cut

has port => (
    is => 'ro',
    isa => 'Int',
    default => sub {
        $ENV{'DATA_RIAK_HTTP_PORT'} || '8098';
    }
);

=attr timeout

The maximum value (in seconds) that a request can go before timing out. Can be set
via the environment variable DATA_RIAK_HTTP_TIMEOUT, and defaults to 15.

=cut

has timeout => (
    is => 'ro',
    isa => 'Int',
    default => sub {
        $ENV{'DATA_RIAK_HTTP_TIMEOUT'} || '15';
    }
);

=method base_uri

The base URI for the Riak server.

=cut

sub base_uri {
    my $self = shift;
    return sprintf('http://%s:%s/', $self->host, $self->port);
}

=method ping

Tests to see if the specified Riak server is answering. Returns 0 for no, 1 for yes.

=cut

sub ping {
    my $self = shift;
    my $response = $self->send({ method => 'GET', uri => 'ping' });
    return 0 unless($response->code eq '200');
    return 1;
}

=method send ($request)

Send a Data::Riak::HTTP::Request to the server. If you pass in a hashref, it will
create the Request object for you on the fly.

=cut

sub send {
    my ($self, $request) = @_;
    unless(blessed $request) {
        $request = Data::Riak::HTTP::Request->new($request);
    }
    my $response = $self->_send($request);
    return $response;
}

sub _send {
    my ($self, $request) = @_;

    my $uri = URI->new( sprintf('%s%s', $self->base_uri, $request->uri) );

    if ($request->has_query) {
        $uri->query_form($request->query);
    }

    my $headers = HTTP::Headers->new(
        ($request->method eq 'GET' ? ('Accept' => $request->accept) : ()),
        ($request->method eq 'POST' || $request->method eq 'PUT' ? ('Content-Type' => $request->content_type) : ()),
    );

    if(my $links = $request->links) {
        $headers->header('Link' => $request->links);
    }

    if(my $indexes = $request->indexes) {
        foreach my $index (@{$indexes}) {
            my $field = $index->{field};
            my $values = $index->{values};
            $headers->header(":X-Riak-Index-$field" => $values);
        }
    }

    my $http_request = HTTP::Request->new(
        $request->method => $uri->as_string,
        $headers,
        $request->data
    );

    my $ua = LWP::UserAgent->new(timeout => $self->timeout);

    my $http_response = $ua->request($http_request);

    my $response = Data::Riak::HTTP::Response->new({
        http_response => $http_response
    });

    return $response;
}

=begin :postlude

=head1 ACKNOWLEDGEMENTS


=end :postlude

=cut

__PACKAGE__->meta->make_immutable;
no Moose;

1;
