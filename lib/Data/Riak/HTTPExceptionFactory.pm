package Data::Riak::HTTPExceptionFactory;

use Moose;
use HTTP::Throwable::Factory;
use namespace::autoclean;

sub throw {
    my ($factory, $exception) = @_;

    HTTP::Throwable::Factory->throw({
        status_code => $exception->transport_response->code,
        reason      => $exception->message,
    });
}

sub new_exception {
    my ($factory, $exception) = @_;

    HTTP::Throwable::Factory->new_exception({
        status_code => $exception->transport_response->code,
        reason      => $exception->message,
    });
}

1;
