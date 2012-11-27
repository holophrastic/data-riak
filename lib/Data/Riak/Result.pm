package Data::Riak::Result;

use strict;
use warnings;

use Moose;

use Data::Riak::Link;

use URI;
use HTTP::Headers::ActionPack 0.05;

with 'Data::Riak::Role::HasRiak';

has [qw(status_code etag content_type vector_clock last_modified)] => (
    is => 'ro',
);

has value => (
    is  => 'rw', # awful. for ->save in WithLocation
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
