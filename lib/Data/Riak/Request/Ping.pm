package Data::Riak::Request::Ping;

use Moose;
use namespace::autoclean;

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'GET',
        uri    => 'ping',
    };
}

with 'Data::Riak::Request';

__PACKAGE__->meta->make_immutable;

1;
