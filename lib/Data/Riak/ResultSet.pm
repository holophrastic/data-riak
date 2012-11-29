package Data::Riak::ResultSet;

use strict;
use warnings;

use Moose;

has results => (
    is       => 'ro',
    isa      => 'ArrayRef[Data::Riak::Result]',
    required => 1
);

sub first { (shift)->results->[0] }

sub all { @{ (shift)->results } }

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
