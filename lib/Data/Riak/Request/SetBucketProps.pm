package Data::Riak::Request::SetBucketProps;

use Moose;
use JSON 'encode_json';
use Data::Riak::Result::SingleJSONValue;
use namespace::autoclean;

has props => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub as_http_request_args {
    my ($self) = @_;

    return {
        method       => 'PUT',
        uri          => sprintf('buckets/%s/props', $self->bucket_name),
        content_type => 'application/json',
        data         => encode_json $self->props,
    };
}

with 'Data::Riak::Request::WithBucket';

has '+result_class' => (
    default => Data::Riak::Result::,
);

__PACKAGE__->meta->make_immutable;

1;
