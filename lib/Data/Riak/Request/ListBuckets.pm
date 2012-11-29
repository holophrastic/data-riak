package Data::Riak::Request::ListBuckets;

use Moose;
use Data::Riak::Result::SingleJSONValue;
use namespace::autoclean;

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'GET',
        uri    => '/buckets',
        query  => { buckets => 'true' },
        accept => 'application/json',
    };
}

with 'Data::Riak::Request';

has '+result_class' => (
    default => Data::Riak::Result::SingleJSONValue::,
);

__PACKAGE__->meta->make_immutable;

1;
