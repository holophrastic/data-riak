package Data::Riak::HTTP;

use Moose;
with 'Data::Riak';

use LWP;
use HTTP::Headers;
use HTTP::Response;
use HTTP::Request;

use Scalar::Util qw/blessed/;

use Data::Riak::HTTP::Request;
use Data::Riak::HTTP::Response;

use Data::Riak::Types qw/HTTPResponse/;

use Data::Dump;

# ABSTRACT: An interface to a Riak server, using its HTTP (REST) interface.


=head1 DESCRIPTION

=head1 SYNOPSIS

=begin :prelude

=end :prelude

=cut

has 'host' => (
    is => 'ro',
    isa => 'Str',
    default => sub { {
        my $return = $ENV{'DATA_RIAK_HTTP_HOST'} || '127.0.0.1';
        return $return;
    } }
);

has 'port' => (
    is => 'ro',
    isa => 'Int',
    default => sub { {
        my $return = $ENV{'DATA_RIAK_HTTP_PORT'} || '8098';
        return $return;
    } }
);

has 'timeout' => (
    is => 'ro',
    isa => 'Int',
    default => sub { {
        my $return = $ENV{'DATA_RIAK_HTTP_TIMEOUT'} || '15';
        return $return;
    } }
);


sub ping {
    my $self = shift;
    my $response = $self->raw('stats');
    unless($response->code eq '200') {
        # don't die, just return 'false'
        return 0; 
    }
    return 1;
}

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

sub send {
    my ($self, $request) = @_;
    unless(blessed $request) {
        $request = Data::Riak::HTTP::Request->new($request);
    }
    my $response = $self->_send($request);
    return $response;
}

sub buckets {
    my $self = shift;
    return $self->raw('buckets?buckets=true');
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

    my $uri = sprintf('http://%s:%s/riak/%s', $self->host, $self->port, $request->uri);
    my $headers = HTTP::Headers->new(
        'Content-Type' => $request->content_type,
    );

    if(my $links = $request->links) {
        my $fixed_links = $request->links->to_string;
        $fixed_links =~ s/###/"/g;
        $headers->header('Link' => $fixed_links);
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

    if($http_response->code eq '400') {
        die 'bad request, probably link malformat';
    }
    return $response;
}

=begin :postlude

=head1 ACKNOWLEDGEMENTS


=end :postlude

=cut

__PACKAGE__->meta->make_immutable;
no Moose;

1;
