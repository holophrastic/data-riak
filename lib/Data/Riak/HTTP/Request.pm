package Data::Riak::HTTP::Request;

use strict;
use warnings;

use Moose;

use HTTP::Headers::ActionPack::LinkList;

with 'Data::Riak::Transport::Request';

has method => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has uri => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has query => (
    is => 'ro',
    isa => 'HashRef',
    predicate => 'has_query'
);

has data => (
    is => 'ro',
    isa => 'Str',
    default => ''
);

has links => (
    is => 'ro',
    isa => 'HTTP::Headers::ActionPack::LinkList',
    # TODO: make this coerce
    default => sub {
        return HTTP::Headers::ActionPack::LinkList->new;
    }
);

has indexes => (
    is => 'ro',
    isa => 'ArrayRef[HashRef]'
);

has content_type => (
    is => 'ro',
    isa => 'Str',
    default => 'text/plain'
);

has accept => (
    is => 'ro',
    isa => 'Str',
    default => '*/*'
);

has headers => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_headers',
);

sub _build_headers { +{} }

sub BUILD {
    my ($self) = @_;
    $self->headers;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
