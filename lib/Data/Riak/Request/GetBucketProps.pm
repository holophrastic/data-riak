package Data::Riak::Request::GetBucketProps;

use Moose;
use Data::Riak::Result::SingleJSONValue;
use namespace::autoclean;

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'GET',
        uri    => sprintf('buckets/%s/props', $self->bucket_name),
        accept => 'application/json',
    };
}

sub _mangle_retval {
    my ($self, $ret) = @_;
    $ret->json_value->{props};
}

with 'Data::Riak::Request::WithBucket';

has '+result_class' => (
    default => Data::Riak::Result::SingleJSONValue::,
);

__PACKAGE__->meta->make_immutable;

1;
