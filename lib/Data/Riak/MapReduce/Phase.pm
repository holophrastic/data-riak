package Data::Riak::MapReduce::Phase;

use JSON::XS qw(encode_json);
use Moose::Role;

=head1 DESCRIPTION

The Phase role contains common code used by all the Data::Riak::MapReduce
phase classes.

=attr keep

Flag controlling whether the results of this phase are included in the final
result of the map/reduce. Defaults to true.

=cut

has keep => (
    is => 'rw',
    isa => 'JSON::XS::Boolean',
    predicate => 'has_keep'
);

1;