package Data::Riak::Request::ListBucketKeys;

use Moose;
use Data::Riak::Result::SingleJSONValue;
use namespace::autoclean;

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'GET',
        uri    => sprintf('buckets/%s/keys', $self->bucket_name),
        accept => 'application/json',
        query  => {
            keys  => 'true',
            props => 'false',
        },
    };
}

with 'Data::Riak::Request::WithBucket';

has '+result_class' => (
    default => Data::Riak::Result::SingleJSONValue::,
);

__PACKAGE__->meta->make_immutable;

1;
