package Data::Riak::Result::WithLocation;

use Moose::Role;
use namespace::autoclean;

has location => (
    is       => 'ro',
    isa      => 'URI',
    required => 1,
);

has bucket_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @uri_parts = split /\//, $self->location->path;
        return $uri_parts[$#uri_parts - 2];
    }
);

has key => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @uri_parts = split /\//, $self->location->path;
        return $uri_parts[$#uri_parts];
    }
);

sub BUILD {}
after BUILD => sub {
    my ($self) = @_;
    $self->bucket_name;
    $self->key;
};

1;
