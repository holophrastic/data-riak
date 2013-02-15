package Data::Riak::Transport::HTTP;

use Moose::Role;
use namespace::autoclean;

with 'Data::Riak::Transport';

requires qw(host port);

has client_id => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { sprintf '%s/%s', ref shift, our $VERSION // 'git' },
);

has base_uri => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_base_uri',
);

has protocol => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http',
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

sub BUILD {}
after BUILD => sub {
    my ($self) = @_;
    $self->base_uri;
};

sub create_request {
    my ($self, $request) = @_;
    return $self->_new_request({
        $self->request_class_args,
        %{ $request->as_http_request_args },
    });
}

1;
