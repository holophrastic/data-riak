package Data::Riak::Async::MapReduce;

use Moose;
use Data::Riak::MapReduce::Phase::Link;
use Data::Riak::MapReduce::Phase::Map;
use Data::Riak::MapReduce::Phase::Reduce;
use namespace::autoclean;

with 'Data::Riak::Role::HasRiak';

has inputs => (
    is => 'ro',
    isa => 'ArrayRef | Str | HashRef',
    required => 1
);

has phases => (
    is => 'ro',
    isa => 'ArrayRef[Data::Riak::MapReduce::Phase]',
    required => 1
);

sub mapreduce {
    my ($self, %options) = @_;

    my $cb = delete $options{cb} || confess 'No callback provided for mapreduce';
    my $error_cb = delete $options{error_cb} || confess 'No error callback provided for mapreduce';

    $self->riak->send_request({
        type     => 'MapReduce',
        cb       => $cb,
        error_cb => $error_cb,
        data     => {
            inputs => $self->inputs,
            query  => [ map { { $_->phase => $_->pack } } @{ $self->phases } ]
        },
        ($options{'chunked'}
            ? (chunked => 1)
            : ()),
    });

    return;
}

__PACKAGE__->meta->make_immutable;

1;
