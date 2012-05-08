package Data::Riak::HTTP::Search::HTTP;

use strict;
use warnings;

use URL::Encode qw/url_encode/;

use Scalar::Util qw/blessed/;

use Moose;

has riak => (
    is => 'ro',
    isa => 'Riak',
    default => sub { {
        return Data::Riak::HTTP->new;
    } }
);

sub search {
    my $self = shift;
}



__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
