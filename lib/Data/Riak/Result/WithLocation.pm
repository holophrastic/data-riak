package Data::Riak::Result::WithLocation;

use Moose::Role;
use namespace::autoclean;

has location => (
    is       => 'ro',
    isa      => 'URI',
    required => 1,
);

has bucket => (
    is      => 'ro',
    isa     => 'Data::Riak::Bucket',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->riak->bucket( $self->bucket_name )
    }
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

# if it's been changed on the server, discard those changes and update the object
sub sync {
    $_[0] = $_[0]->bucket->get($_[0]->key)
}

# if it's been changed locally, save those changes to the server
sub save {
    my $self = shift;
    return $self->bucket->add($self->key, $self->value, { links => $self->links });
}

sub linkwalk {
    my ($self, $params) = @_;
    return undef unless $params;
    return $self->riak->linkwalk({
        bucket => $self->bucket_name,
        object => $self->key,
        params => $params
    });
}

1;
