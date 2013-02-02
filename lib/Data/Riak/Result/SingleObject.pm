package Data::Riak::Result::SingleObject;
# ABSTRACT: Single result containing an object

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Result::Object';
with 'Data::Riak::Result::Single';

=head1 DESCRIPTION

A result class for Riak requests returning one full object, such as C<GetObject>
and C<StoreObject>.

It is identical to L<Data::Riak::Result::Object>, but also composes
L<Data::Riak::Result::Single> to avoid the results being wrapped in a
L<Data::Riak::ResultSet>, as there will only ever be one result.

=cut

__PACKAGE__->meta->make_immutable;

1;
