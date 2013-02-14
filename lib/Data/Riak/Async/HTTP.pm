package Data::Riak::Async::HTTP;

use Moose;
use AnyEvent::HTTP;
use namespace::autoclean;

has host => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has port => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has protocol => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http',
);

has client_id => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { sprintf '%s/%s', __PACKAGE__, our $VERSION // 'git' },
);

has base_uri => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_base_uri',
);

sub _build_base_uri {
    my $self = shift;
    return sprintf('%s://%s:%s/', $self->protocol, $self->host, $self->port);
}

has request_class => (
    is      => 'ro',
    isa     => 'ClassName',
    default => Data::Riak::HTTP::Request::,
    handles => {
        _new_request => 'new',
    },
);

has request_class_args => (
    traits  => ['Hash'],
    isa     => 'HashRef',
    default => sub { +{} },
    handles => {
        request_class_args => 'elements',
    },
);

has exception_handler => (
    is      => 'ro',
    isa     => 'Data::Riak::HTTP::ExceptionHandler',
    builder => '_build_exception_handler',
);

sub _build_exception_handler {
    Data::Riak::HTTP::ExceptionHandler::Default->new;
}

sub create_request {
    my ($self, $request) = @_;
    return $self->_new_request({
        $self->request_class_args,
        %{ $request->as_http_request_args },
    });
}

sub send {
    my ($self, $request, $cb) = @_;

    my $http_request = $self->create_request($request);

    $self->_send($http_request, sub {
        my ($http_response) = @_;

        # FIXME: don't croak in event loop. signal exception through user
        #        callback
        $self->exception_handler->try_handle_exception(
            $request, $http_request, $http_response,
        );

        $cb->($http_response);
    });

    return;
}

sub _send {
    my ($self, $request, $cb) = @_;

    my $uri = URI->new( sprintf('%s%s', $self->base_uri, $request->uri) );

    if ($request->has_query) {
        $uri->query_form($request->query);
    }

    my $headers = HTTP::Headers->new(
        'X-Riak-ClientId' => $self->client_id,
        ($request->method eq 'GET' ? ('Accept' => $request->accept) : ()),
        ($request->method eq 'POST' || $request->method eq 'PUT' ? ('Content-Type' => $request->content_type) : ()),
        %{ $request->headers },
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

    my %plain_headers;
    $http_request->headers->scan(sub {
        # FIXME: overwrites duplicate headers
        $plain_headers{$_[0]} = $_[1];
    });

    # TODO: timeout
    http_request $http_request->method, $http_request->uri,
        headers => \%plain_headers, body => $http_request->content, sub {
            my ($body, $hdr) = @_;

            my $http_response = HTTP::Response->new(
                delete $hdr->{Status}, delete $hdr->{Reason},
                HTTP::Headers->new(%{ $hdr }), $body,
            );

            my $response = Data::Riak::HTTP::Response->new({
                http_response => $http_response
            });

            $cb->($response);
        };

    return;
}

__PACKAGE__->meta->make_immutable;

1;
