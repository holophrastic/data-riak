package Data::Riak::HTTP::Request;

use strict;
use warnings;

use Moose;

use HTTP::Headers::ActionPack::LinkList;

has method => (
    is => 'ro',
    isa => 'Str',
    default => 'GET'
);

has uri => (
    is => 'ro',
    isa => 'Str',
    required => 1
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

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
