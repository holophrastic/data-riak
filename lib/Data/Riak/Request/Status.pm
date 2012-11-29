package Data::Riak::Request::Status;

use Moose;
use Data::Riak::Result::SingleJSONValue;
use Data::Riak::Exception::StatsNotEnabled;
use namespace::autoclean;

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'GET',
        uri    => 'stats',
        accept => 'application/json',
    };
}

sub _build_http_exception_classes {
    return {
        404 => Data::Riak::Exception::StatsNotEnabled::,
    };
}

with 'Data::Riak::Request',
     'Data::Riak::Request::WithHTTPExceptionHandling';

has '+result_class' => (
    default => Data::Riak::Result::SingleJSONValue::,
);

__PACKAGE__->meta->make_immutable;

1;
