package Data::Riak::Request::GetObject;

use Moose;
use Data::Riak::Result::Object;
use Data::Riak::Exception::ObjectNotFound;
use Data::Riak::Exception::MultipleSiblingsAvailable;
use namespace::autoclean;

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'GET',
        uri    => sprintf('buckets/%s/keys/%s', $self->bucket_name, $self->key),
    };
}

has http_exception_classes => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[Str]',
    builder => '_build_http_exception_classes',
    handles => {
        exception_class_for_http_status => 'get',
    },
);

sub _build_http_exception_classes {
    return {
        300 => Data::Riak::Exception::MultipleSiblingsAvailable::,
        404 => Data::Riak::Exception::ObjectNotFound::,
    };
}

with 'Data::Riak::Request::WithObject',
     'Data::Riak::Request::WithHTTPExceptionHandling';

has '+result_class' => (
    default => Data::Riak::Result::Object::,
);

__PACKAGE__->meta->make_immutable;

1;
