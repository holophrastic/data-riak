package Data::Riak::HTTP::Request;

use strict;
use warnings;

use Moose;

has method => (
    is => 'ro',
    isa => 'Str',
    default => 'GET'
);

has uri => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has data => (
    is => 'ro',
    isa => 'Str',
    default => ''
);

has links => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { {
        my $array_ref = [];
        return $array_ref;
    } }
);

has content_type => (
    is => 'ro',
    isa => 'Str',
    default => 'text/plain'
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
