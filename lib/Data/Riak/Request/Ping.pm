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
        # This is a bit of a hack. Maybe we want to allow predicate functions to
        # be provided, or at least regexen or some such.
        (map { ($_ => undef) } 500 .. 599),
    };
}

sub _mangle_retval {
    my ($self, $res) = @_;
    $res->status_code == 200 ? 1 : 0
}

with 'Data::Riak::Request',
     'Data::Riak::Request::WithHTTPExceptionHandling';

has '+result_class' => (
    default => Data::Riak::Result::SingleValue::,
);

__PACKAGE__->meta->make_immutable;

1;
