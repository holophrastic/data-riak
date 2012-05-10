package Data::Riak::ResultSet;

use strict;
use warnings;

use Moose;

has results => (
    is => 'rw',
    isa => 'ArrayRef[Data::Riak::Result]',
    required => 1
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
