package Data::Riak::Link;

use strict;
use warnings;

use Moose;

use URI;
use HTTP::Headers::ActionPack::LinkHeader;

with 'Data::Riak::Role::HasRiak',
     'Data::Riak::Role::HasBucket',
     'Data::Riak::Role::HasLocation';

has link_header => (
    is => 'ro',
    isa => 'HTTP::Headers::ActionPack::LinkHeader',
    required => 1
);

sub build_location {
    URI->new( (shift)->link_header->href );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
