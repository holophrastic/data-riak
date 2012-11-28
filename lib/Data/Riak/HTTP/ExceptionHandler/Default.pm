package Data::Riak::HTTP::ExceptionHandler::Default;

use Moose;
use HTTP::Status 'is_client_error', 'is_server_error';
use Data::Riak::Exception::ClientError;
use Data::Riak::Exception::ServerError;
use namespace::autoclean;

extends 'Data::Riak::HTTP::ExceptionHandler';

sub _build_honour_request_specific_exceptions { 1 }

sub _build_fallback_handler {
    [[\&is_client_error, Data::Riak::Exception::ClientError::],
     [\&is_server_error, Data::Riak::Exception::ServerError::]]
}

__PACKAGE__->meta->make_immutable;

1;
