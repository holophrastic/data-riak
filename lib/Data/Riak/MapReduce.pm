package Data::Riak::MapReduce;

use strict;
use warnings;

use Moose;

use JSON::XS qw/encode_json/;

has riak => (
    is => 'ro',
    isa => 'Data::Riak',
    required => 1
);

has inputs => (
    is => 'ro',
    isa => 'ArrayRef | Str',
    required => 1
);

has map_phase => (
    is => 'ro',
    isa => 'HashRef',
    predicate => 'has_map_phase'
);

has reduce_phase => (
    is => 'ro',
    isa => 'HashRef',
    predicate => 'has_reduce_phase'
);

has link_phase => (
    is => 'ro',
    isa => 'HashRef',
    predicate => 'has_link_phase'
);

sub mapreduce {
    my ($self, %options) = @_;

    my $uri = "mapred";
    $uri .= "?chunked=true" if($options{'chunked'});

    return $self->riak->send_request({
        content_type => 'application/json',
        method => 'POST',
        uri => $uri,
        data => encode_json({
            inputs => $self->inputs,
            query => [
                ($self->has_map_phase ? { 'map' => $self->map_phase } : ()),
                ($self->has_reduce_phase ? { 'reduce' => $self->reduce_phase } : ()),
                ($self->has_link_phase ? { 'link' => $self->link_phase } : ()),
            ]
        })
    });
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
