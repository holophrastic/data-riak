package Data::Riak::Role::HasLocation;

use strict;
use warnings;

use Moose::Role;

use URI;

has location => (
    is => 'ro',
    isa => 'URI',
    lazy => 1,
    builder => 'build_location'
);

requires 'build_location';

has bucket_name => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        my @uri_parts = split /\//, $self->location->path;
        return $uri_parts[$#uri_parts - 2];
    }
);

has key => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        my @uri_parts = split /\//, $self->location->path;
        return $uri_parts[$#uri_parts];
    }
);

no Moose::Role;

1;

__END__
