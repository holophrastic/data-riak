package Data::Riak::Result;

use Moose;
use MooseX::StrictConstructor;

with 'Data::Riak::Role::HasRiak';

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

has value => (
    is  => 'ro',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
