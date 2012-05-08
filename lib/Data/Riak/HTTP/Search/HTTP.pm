package Data::Riak::HTTP::Search::HTTP;

use strict;
use warnings;

use URL::Encode qw/url_encode/;

use Moose;

has riak => (
    is => 'ro',
    isa => 'Data::Riak::HTTP',
    required => 1
);

sub search {
    my $self = shift;
}



__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
