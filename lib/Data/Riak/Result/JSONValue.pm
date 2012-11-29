package Data::Riak::Result::JSONValue;

use Moose::Role;
use JSON 'decode_json';
use namespace::autoclean;

sub json_value {
    my ($self) = @_;
    decode_json $self->value;
}

1;
