package Data::Riak::Result::SingleJSONValue;
# ABSTRACT: Single result containing JSON data

use Moose;
use JSON 'decode_json';
use namespace::autoclean;

extends 'Data::Riak::Result';
with 'Data::Riak::Result::JSONValue',
     'Data::Riak::Result::Single';

=head1 DESCRIPTION

This is a result class for requests returning a single result containing JSON
encoded data. It applies L<Data::Riak::Result::JSONValue> and
L<Data::Riak::Result::Single>.

=cut

__PACKAGE__->meta->make_immutable;

1;
