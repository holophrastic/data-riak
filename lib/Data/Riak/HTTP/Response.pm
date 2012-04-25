package Data::Riak::HTTP::Response;

use Moose;

has 'status_code' => (
    is => 'ro',
    isa => 'Int',
    required => 1
);

has 'content' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
