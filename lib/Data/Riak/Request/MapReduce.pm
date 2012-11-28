package Data::Riak::Request::MapReduce;

use Moose;
use Data::Riak::Result::Object;
use JSON 'encode_json';
use namespace::autoclean;

has data => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has chunked => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub as_http_request_args {
    my ($self) = @_;

    return +{
        method       => 'POST',
        uri          => 'mapred',
        content_type => 'application/json',
        data         => encode_json($self->data),
        ($self->chunked ? (query => { chunked => 'true' }) : ()),
    };
}

with 'Data::Riak::Request';

__PACKAGE__->meta->make_immutable;

1;
