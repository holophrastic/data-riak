package Data::Riak::Request::MapReduce;

use Moose;
use Data::Riak::Result::Object;
use Data::Riak::Exception::FunctionFailed;
use Data::Riak::Exception::Timeout;
use JSON 'encode_json';
use namespace::autoclean;

has data => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has chunked => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub as_http_request_args {
    my ($self) = @_;

    return +{
        method       => 'POST',
        uri          => 'mapred',
        content_type => 'application/json',
        data         => encode_json($self->data),
        ($self->chunked ? (query => { chunked => 'true' }) : ()),
    };
}

sub _build_http_exception_classes {
    return {
        500 => Data::Riak::Exception::FunctionFailed::,
        503 => Data::Riak::Exception::Timeout::,
    };
}

with 'Data::Riak::Request',
     'Data::Riak::Request::WithHTTPExceptionHandling';

__PACKAGE__->meta->make_immutable;

1;
