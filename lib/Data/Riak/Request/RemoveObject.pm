package Data::Riak::Request::RemoveObject;

use Moose;
use Data::Riak::Result::MaybeVClock;
use namespace::autoclean;

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'DELETE',
        uri    => sprintf('buckets/%s/keys/%s', $self->bucket_name, $self->key),
    };
}

sub _build_http_exception_classes {
    return {
        404 => undef,
    };
}

with 'Data::Riak::Request::WithObject',
     'Data::Riak::Request::WithHTTPExceptionHandling';

has '+result_class' => (
    default => Data::Riak::Result::MaybeVClock::,
);

__PACKAGE__->meta->make_immutable;

1;
