package Data::Riak::Result::JSONValue;
# ABSTRACT: A result containing JSON data

use Moose::Role;
use JSON 'decode_json';
use namespace::autoclean;

=head1 DESCRIPTION

Results for requests resulting in JSON data use this role to provide convenient
access to the decoded body payload.

=method json_value

=cut

sub json_value {
    my ($self) = @_;
    decode_json $self->value;
}

1;
