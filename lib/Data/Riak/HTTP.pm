package Data::Riak::HTTP;
# ABSTRACT: An interface to a Riak server, using its HTTP (REST) interface

use strict;
use warnings;

use Moose;

use LWP::UserAgent;
use LWP::ConnCache;
use HTTP::Headers;
use HTTP::Response;
use HTTP::Request;
use JSON 'decode_json';

use Data::Riak::HTTP::Request;
use Data::Riak::HTTP::Response;

use Data::Riak::TransportException;

use namespace::autoclean;

with 'Data::Riak::Transport';

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

=attr user_agent

This is the instance of L<LWP::UserAgent> we use to talk to Riak.

=cut

our $CONN_CACHE;

has user_agent => (
    is => 'ro',
    isa => 'LWP::UserAgent',
    lazy => 1,
    default => sub {
        my $self = shift;

        # NOTE:
        # Much of the following was copied from
        # Net::Riak (franck cuny++ && robin edwards++)
        # - SL

        # The Links header Riak returns (esp. for buckets) can get really long,
        # so here increase the MaxLineLength LWP will accept (default = 8192)
        my %opts = @LWP::Protocol::http::EXTRA_SOCK_OPTS;
        $opts{MaxLineLength} = 65_536;
        @LWP::Protocol::http::EXTRA_SOCK_OPTS = %opts;

        my $ua = LWP::UserAgent->new(
            timeout => $self->timeout,
            keep_alive => 1
        );

        $CONN_CACHE ||= LWP::ConnCache->new;

        $ua->conn_cache( $CONN_CACHE );

        $ua;
    }
);

has client_id => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { sprintf '%s/%s', __PACKAGE__, our $VERSION // 'git' },
);

=method base_uri

The base URI for the Riak server.

=cut

sub base_uri {
    my $self = shift;
    return sprintf('http://%s:%s/', $self->host, $self->port);
}

sub create_request {
    my ($self, $request) = @_;
    return Data::Riak::HTTP::Request->new($request->as_http_request_args);
}

=method send ($request)

Send a Data::Riak::HTTP::Request to the server.

=cut

sub send {
    my ($self, $request) = @_;

    my $http_request = $self->create_request($request);
    my $http_response = $self->_send($http_request);

    if ($request->does('Data::Riak::Request::WithHTTPExceptionHandling')) {
        my $expt_class = $request->exception_class_for_http_status(
            $http_response->code,
        );

        $expt_class->throw({
            request            => $request,
            transport_request  => $http_request,
            transport_response => $http_response,
        }) if $expt_class;
    }

    Data::Riak::TransportException->throw({
        message  => $http_response->http_response->message, # FIXME
        request  => $http_request,
        response => $http_response,
    }) if $http_response->is_error;

    return $http_response;
}

sub _send {
    my ($self, $request) = @_;

    my $uri = URI->new( sprintf('%s%s', $self->base_uri, $request->uri) );

    if ($request->has_query) {
        $uri->query_form($request->query);
    }

    my $headers = HTTP::Headers->new(
        'X-Riak-ClientId' => $self->client_id,
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

    my $http_response = $self->user_agent->request($http_request);

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

1;
