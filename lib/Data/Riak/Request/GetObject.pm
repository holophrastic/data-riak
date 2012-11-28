package Data::Riak::Request::GetObject;

use Moose;
use Data::Riak::Result::Object;
use namespace::autoclean;

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'GET',
        uri    => sprintf('buckets/%s/keys/%s', $self->bucket_name, $self->key),
    };
}

with 'Data::Riak::Request::WithObject';

has '+result_class' => (
    default => Data::Riak::Result::Object::,
);

__PACKAGE__->meta->make_immutable;

1;
