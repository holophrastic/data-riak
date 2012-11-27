package Data::Riak::HTTP::Response;

use strict;
use warnings;

use Moose;
use URI;
use HTTP::Headers::ActionPack 0.05;

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

sub create_results {
    my ($self, $riak, $result_class) = @_;

    return map {
        $self->_create_result($riak, $result_class, $_)
    } @{ $self->parts };
}

my %header_values = (
    etag          => 'etag',
    content_type  => 'content-type',
    vector_clock  => 'x-riak-vclock',
    last_modified => 'last_modified',
);

sub _create_result {
    my ($self, $riak, $result_class, $http_message) = @_;

    HTTP::Headers::ActionPack->new->inflate( $http_message->headers );

    my $links = $http_message->header('link');
    my %result_args = (
        riak          => $riak,
        status_code   => $self->http_response->code,
        value         => $http_message->content,
        (map {
            ($_ => scalar $http_message->header($header_values{$_}))
        } keys %header_values),
        links         => [map {
            Data::Riak::Link->from_link_header($_)
        } $links ? $links->iterable : ()],
    );

    if ($result_class->does('Data::Riak::Result::WithLocation')) {
        $result_args{location} = $http_message->can('request')
            ? $http_message->request->uri
            : (URI->new( $http_message->header('location') )
                   || die 'Cannot determine location from ' . $http_message);
    }

    return $result_class->new(\%result_args);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
