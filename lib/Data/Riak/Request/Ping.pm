package Data::Riak::Request::Ping;

use Moose;
use Data::Riak::Result::SingleValue;
use namespace::autoclean;

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'GET',
        uri    => 'ping',
    };
}

sub _build_http_exception_classes {
    return {
        500 => undef,
    };
}

with 'Data::Riak::Request',
     'Data::Riak::Request::WithHTTPExceptionHandling';

has '+result_class' => (
    default => Data::Riak::Result::SingleValue::,
);

__PACKAGE__->meta->make_immutable;

1;
