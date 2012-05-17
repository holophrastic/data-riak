package Data::Riak::Role::HasRiak;

use strict;
use warnings;

use Moose::Role;

use Data::Riak;

has riak => (
    is => 'ro',
    isa => 'Data::Riak',
    required => 1
);

no Moose::Role;

1;

__END__
