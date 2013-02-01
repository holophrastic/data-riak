package Data::Riak::Result::Single;
# ABSTRACT: Results without the need of a ResultSet

use Moose::Role;
use namespace::autoclean;

=head1 DESCRIPTION

Normally, requests to Riak can return more than one result. That set of results
is usually wrapped up in a L<Data::Riak::ResultSet> before being returned to the
user.

However, some requests will only ever result in a single result. This result
role indicates that and will prevent the returned result from being wrapped in a
ResultSet.

=cut

1;
