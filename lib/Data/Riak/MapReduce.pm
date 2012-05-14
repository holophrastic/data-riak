package Data::Riak::MapReduce;

use strict;
use warnings;

use Moose;

use JSON::XS;

use Data::Riak::MapReduce::MapReduceComponent;

has riak => (
    is => 'ro',
    isa => 'Data::Riak',
    required => 1
);

has config => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    default => sub { +{} }
);

has map => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} }
);

has reduce => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} }
);

has link => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} }
);

has inputs => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] }
);

sub mapreduce {
    my ($self, $raw_query) = @_;

    my $uri = "mapred";
    $uri .= "?chunked=true" if($self->config->{chunked});

    return $self->riak->send_request({
        content_type => 'application/json',
        method => 'POST',
        uri => $uri,
        data => encode_json({
            inputs => $self->inputs,
            query => [
                { 'map'    => $self->map },
                { 'reduce' => $self->reduce },
            ]
        })
    });
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
