package Data::Riak::Request;

use Moose::Role;
use MooseX::StrictConstructor;
use namespace::autoclean;

has result_class => (
    is      => 'ro',
    isa     => 'ClassName',
    default => Data::Riak::Result::,
    handles => {
        new_result  => 'new',
        result_does => 'does',
    },
);

requires qw(as_http_request_args);

1;
