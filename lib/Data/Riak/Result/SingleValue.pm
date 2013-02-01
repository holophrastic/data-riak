package Data::Riak::Result::SingleValue;
# ABSTRACT: Result class for requests with a single result

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Result';
with 'Data::Riak::Result::Single';

=head1 SEE ALSO

L<Data::Riak::Result::Single>

=cut

__PACKAGE__->meta->make_immutable;

1;
