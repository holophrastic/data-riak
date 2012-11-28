package Data::Riak::Request::GetBucketProps;

use Moose;
use namespace::autoclean;

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'GET',
        uri    => sprintf('buckets/%s/props', $self->bucket_name),
    };
}

with 'Data::Riak::Request::WithBucket';

__PACKAGE__->meta->make_immutable;

1;
