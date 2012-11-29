package Data::Riak::Request::WithHTTPExceptionHandling;

use Moose::Role;
use namespace::autoclean;

with 'Data::Riak::Request';

has http_exception_classes => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[ClassName|Undef]',
    builder => '_build_http_exception_classes',
    handles => {
        has_exception_class_for_http_status => 'exists',
        exception_class_for_http_status     => 'get',
    },
);

requires '_build_http_exception_classes';

1;
