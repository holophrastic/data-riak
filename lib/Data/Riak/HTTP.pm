package Data::Riak::HTTP;

use Moose;
with 'Data::Riak';

# ABSTRACT: An interface to a Riak server, using its HTTP (REST) interface

use LWP;
use HTTP::Headers;
use HTTP::Response;
use HTTP::Request;

use Data::Riak::MapReduce;

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
    my $response = $self->raw('ping');
    return 0 unless($response->code eq '200');
    return 1;
}

=method raw ($uri, $method)

Send a URL to the riak server, unchanged. $method defaults to GET.

=cut

sub raw {
    my ($self, $uri, $method) = @_;
    $method ||= "GET";
    my $request = Data::Riak::HTTP::Request->new({
        uri => $uri,
        method => $method
    });
    my $response = $self->_send($request);
    return $response;
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

=method buckets

Get the list of buckets. This is NOT RECOMMENDED for production systems, as Riak
has to essentially walk the entire database. Here purely as a tool for debugging
and convenience.

=cut

sub buckets {
    my $self = shift;
    return $self->raw('/buckets?buckets=true');
}

# convenience method
sub mapreduce {
    my ($self, $args) = @_;
    my $config = $args->{config};
    my $query = $args->{query};

    my $mr = Data::Riak::MapReduce->new($config);
    return $mr->mapreduce($query);
}

sub linkwalk {
    my ($self, $args) = @_;
    my $object = $args->{object} || die 'You must have an object to linkwalk';
    my $bucket = $args->{bucket} || die 'You must have a bucket for the original object to linkwalk';

    my $request_str = "$bucket/$object/";
    my $params = $args->{params};

    foreach my $depth (@$params) {
        if(scalar @{$depth} == 2) {
            unshift @{$depth}, $bucket;
        }
        my ($buck, $tag, $keep) = @{$depth};
        $request_str .= "$buck,$tag,$keep/";
    }
    my $request = Data::Riak::HTTP::Request->new({
        method => 'GET',
        uri => $request_str
    });

    return $self->_send($request);
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
