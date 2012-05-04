package Data::Riak::HTTP::Request;

use strict;
use warnings;

use Moose;

use HTTP::Headers::ActionPack;
use HTTP::Headers::ActionPack::LinkList;

use Data::Riak::Types qw/HTTPHeadersActionPackLinkList/;

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
    isa => 'HTTPHeadersActionPackLinkList',
    default => sub { {
        return HTTP::Headers::ActionPack::LinkList->new;
    } }
);

has content_type => (
    is => 'ro',
    isa => 'Str',
    default => 'text/plain'
);

has namespace => (
    is => 'ro',
    isa => 'Str',
    default => 'riak'
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
