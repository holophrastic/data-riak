package Data::Riak::Request::RemoveObject;

use Moose;
use namespace::autoclean;

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'DELETE',
        uri    => sprintf('buckets/%s/keys/%s', $self->bucket_name, $self->key),
    };
}

with 'Data::Riak::Request::WithObject';

has '+result_class' => (
    default => Data::Riak::Result::,
);

__PACKAGE__->meta->make_immutable;

1;
