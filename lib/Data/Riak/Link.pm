package Data::Riak::Link;

use strict;
use warnings;

use Moose;

with 'Data::Riak::Role::HasRiak';


__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
