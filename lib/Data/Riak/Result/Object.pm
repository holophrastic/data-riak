package Data::Riak::Result::Object;
# ABSTRACT: A result containing a full object

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Result';
with 'Data::Riak::Result::WithLocation',
     'Data::Riak::Result::WithLinks',
     'Data::Riak::Result::WithVClock';

=head1 DESCRIPTION

A result class representing a full object retrieved from Riak. This composes the
roles

=over 4

=item * L<Data::Riak::Result::WithLocation>

=item * L<Data::Riak::Result::WithLinks>

=item * L<Data::Riak::Result::WithVClock>

=back

=attr etag

ETag header as provided by Riak. May or may not be present, as indicated by the
C<has_etag> predicate method.

=cut

has etag => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_etag',
);

=attr last_modified

A L<HTTP::Headers::ActionPack::DateHeader> describing the time the object was
last modified in Riak. May or may not be present, as indicated by the
C<has_last_modified> predicate method.

=cut

has last_modified => (
    is        => 'ro',
    isa       => 'HTTP::Headers::ActionPack::DateHeader',
    predicate => 'has_last_modified',
);

__PACKAGE__->meta->make_immutable;

1;
