package Data::Riak::MapReduce::Phase;

use Moose::Role;

=head1 DESCRIPTION

The Phase role contains common code used by all the Data::Riak::MapReduce
phase classes.

=attr keep

Flag controlling whether the results of this phase are included in the final
result of the map/reduce.

=method pack

The C<pack> method is required to be implemented by consumers of this role.

=cut

has keep => (
    is        => 'ro',
    isa       => 'Bool',
    predicate => 'has_keep',
);

requires 'pack';

no Moose::Role; 1;
