package Data::Riak::Async::MapReduce;

use Moose;
use namespace::autoclean;

sub mapreduce {
    my ($self, %options) = @_;

    my $cb = delete $options{cb} || confess 'No callback provided for mapreduce';

    $self->riak->send_request({
        type => 'MapReduce',
        cb   => $cb,
        data => {
            inputs => $self->inputs,
            query => [ map { { $_->phase => $_->pack } } @{ $self->phases } ]
        },
        ($options{'chunked'}
            ? (chunked => 1)
            : ()),
    });

    return;
}

__PACKAGE__->meta->make_immutable;

1;
