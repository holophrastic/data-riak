package Data::Riak::HTTP::ResultSet;

use strict;
use warnings;

use Moose;

has results => (
    is => 'rw',
    isa => 'ArrayRef[Data::Riak::HTTP::Result]',
    required => 1
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
