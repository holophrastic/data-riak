package Data::Riak::Result;

use Moose;
use MooseX::StrictConstructor;

with 'Data::Riak::Role::HasRiak', 'MooseX::Clone';

has status_code => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has content_type => (
    is       => 'ro',
    isa      => 'HTTP::Headers::ActionPack::MediaType',
    required => 1,
);

has _value => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => 'value',
);

sub value {
    my $self = shift;
    return $self->_value unless @_;
    return $self->clone(value => shift);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
