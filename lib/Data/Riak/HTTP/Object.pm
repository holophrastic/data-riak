package Data::Riak::HTTP::Object;

use strict;
use warnings;

use Moose;

has riak => (
    is => 'ro'
    isa => 'Data::Riak::HTTP',
    default => sub { {
        return Data::Riak::HTTP->new;
    } }
);

has bucket_name => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has value => (
    is => 'rw',
    isa => 'Str',
    default => ''
);

has links => (
    is => 'rw',
    isa => 'ArrayRef[ArrayRef[Str]]',
    default => []
);

sub sync {}

sub linkwalk {
    my ($self, $params) = @_;
    return undef unless $params;
    return $self->riak->linkwalk({
        bucket => $self->bucket_name,
        object => $self->name,
        params => $params
    );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
