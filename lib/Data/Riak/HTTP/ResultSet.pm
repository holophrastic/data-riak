package Data::Riak::HTTP::ResultSet;

use strict;
use warnings;

use Moose;
use Data::Riak::Types qw/RiakResult/;


has results => (
    is => 'rw',
    isa => 'ArrayRef[RiakResult]',
    required => 1
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
