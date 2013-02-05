package Data::Riak::Result::MaybeWithVClock;
# ABSTRACT: Results with vector clock headers

use Moose::Role;
use namespace::autoclean;

=attr vector_clock

The result's vector clock as returned by Riak's C<X-Riak-VClock> headers.

=cut

has vector_clock => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_vector_clock',
);

1;
