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

use Data::Dump;

=attr host

The host the Riak server is on. Can be set via the environment variable
DATA_RIAK_HTTP_HOST, and defaults to 127.0.0.1.

=cut

has host => (
    is => 'ro',
    isa => 'Str',
    default => sub { {
        my $return = $ENV{'DATA_RIAK_HTTP_HOST'} || '127.0.0.1';
        return $return;
    } }
);

=attr port

The port of the host that the riak server is on. Can be set via the environment
variable DATA_RIAK_HTTP_PORT, and defaults to 8098.

=cut

has port => (
    is => 'ro',
    isa => 'Int',
    default => sub { {
        my $return = $ENV{'DATA_RIAK_HTTP_PORT'} || '8098';
        return $return;
    } }
);

=attr timeout

The maximum value (in seconds) that a request can go before timing out. Can be set
via the environment variable DATA_RIAK_HTTP_TIMEOUT, and defaults to 15.

=cut

has timeout => (
    is => 'ro',
    isa => 'Int',
    default => sub { {
        my $return = $ENV{'DATA_RIAK_HTTP_TIMEOUT'} || '15';
        return $return;
    } }
);

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

    my $uri = sprintf('http://%s:%s/%s', $self->host, $self->port, $request->uri);
    my $headers = HTTP::Headers->new(
        'Content-Type' => $request->content_type,
    );

    if(my $links = $request->links) {
        $headers->header('Link' => $request->links);
    }

    my $http_request = HTTP::Request->new(
        $request->method => $uri,
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
