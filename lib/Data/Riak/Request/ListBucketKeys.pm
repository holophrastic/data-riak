package Data::Riak::Request::ListBucketKeys;

use Moose;
use namespace::autoclean;

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'GET',
        uri    => sprintf('buckets/%s/keys', $self->bucket_name),
        query  => {
            keys  => 'true',
            props => 'false',
        },
    };
}

with 'Data::Riak::Request::WithBucket';

__PACKAGE__->meta->make_immutable;

1;
