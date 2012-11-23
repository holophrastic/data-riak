package Data::Riak::HTTP::Response;

use strict;
use warnings;

use Moose;

use overload '""' => 'as_string', fallback => 1;

my $_deconstruct_parts;

has 'parts' => (
    is => 'ro',
    isa => 'ArrayRef[HTTP::Message]',
    lazy => 1,
    default => sub {
        my $self = shift;
        my @parts = $_deconstruct_parts->( $self->http_response );
        return \@parts;
    }
);

has 'http_response' => (
    is => 'ro',
    isa => 'HTTP::Response',
    required => 1,
    handles => {
        code        => 'code',
        status_code => 'code',
        message     => 'content',
        value       => 'content',
        is_success  => 'is_success',
        is_error    => 'is_error',
        as_string   => 'as_string',
        header      => 'header',
        headers     => 'headers'
    }
);

$_deconstruct_parts = sub {
    my $message = shift;
    return () unless $message->content;
    my @parts = $message->parts;
    return $message unless @parts;
    return map { $_deconstruct_parts->( $_ ) } @parts;
};

with 'Data::Riak::Transport::Response';

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
