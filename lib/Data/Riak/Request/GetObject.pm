package Data::Riak::Request::GetObject;

use Moose;
use Data::Riak::Result::SingleObject;
use Data::Riak::Exception::ObjectNotFound;
use Data::Riak::Exception::MultipleSiblingsAvailable;
use namespace::autoclean;

has accept => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_accept',
);

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'GET',
        uri    => sprintf('buckets/%s/keys/%s', $self->bucket_name, $self->key),
        ($self->has_accept ? (accept => $self->accept) : ()),
    };
}

sub _build_http_exception_classes {
    return {
        300 => Data::Riak::Exception::MultipleSiblingsAvailable::,
        404 => Data::Riak::Exception::ObjectNotFound::,
    };
}

with 'Data::Riak::Request::WithObject',
     'Data::Riak::Request::WithHTTPExceptionHandling';

has '+result_class' => (
    default => Data::Riak::Result::SingleObject::,
);

__PACKAGE__->meta->make_immutable;

1;
