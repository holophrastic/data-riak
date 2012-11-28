package Data::Riak::Request::WithHTTPExceptionHandling;

use Moose::Role;
use namespace::autoclean;

with 'Data::Riak::Request';

requires 'exception_class_for_http_status';

1;
