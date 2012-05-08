package Data::Riak::HTTP::Response;

use strict;
use warnings;

use Moose;

use Data::Riak::HTTP::Result;
use Data::Riak::HTTP::ResultSet;

has 'code' => (
    is => 'ro',
    isa => 'Int',
    lazy => 1,
    default => sub { {
        my $self = shift;
        return $self->http_response->code;
    } }
);

has 'parts' => (
    is => 'ro',
    isa => 'ArrayRef[HTTP::Message]',
    lazy => 1,
    default => sub { {
        my $self = shift;

        if($self->is_error) {
            die "Can't get parts from a response with an error code";
        }

        unless($self->is_multi) {
            die "Can't get parts from a message that isn't multipart";
        }

        my @parts = $self->http_response->parts->parts;
        return \@parts;
    } }
);

has 'http_response' => (
    is => 'ro',
    isa => 'HTTP::Response',
    required => 1
);


sub is_multi {
    my $self = shift;
    if($self->http_response->content_type =~ /^multipart/ ) {
        return 1;
    }
    return 0;
}

sub is_error {
    my $self = shift;

    # simple case for now
    if($self->code eq '404') {
        return 1;
    }
    return 0;
}

sub results {
    my $self = shift;

    # in case they didn't check this first
    if($self->is_error) {
        die "Got an error from the server, no result";
    }

    # did we only get one?
    unless($self->is_multi) {
        my $result = $self->result;
        my $resultset = Data::Riak::HTTP::ResultSet->new({ results => [ $result ] });
        return $resultset;
    }

    my $results;
    foreach my $part (@{$self->parts}) {
        push @{$results}, Data::Riak::HTTP::Result->new({ http_message => $part });
    }
    my $resultset = Data::Riak::HTTP::ResultSet->new({ results => $results });

}

sub result {
    my $self = shift;

    # in case they didn't check this first
    if($self->is_error) {
        die "Got an error from the server, no result";
    }

    # also, something the user should check first
    if($self->is_multi) {
        die "Can't give a single result for a multipart response!";
    }

    return Data::Riak::HTTP::Result->new({ http_message => $self->http_response });
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
