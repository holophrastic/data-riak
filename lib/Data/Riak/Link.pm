package Data::Riak::Link;

use strict;
use warnings;

use Moose;

use URL::Encode qw/url_encode/;
use HTTP::Headers::ActionPack::LinkHeader;

has bucket => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has key => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has riaktag => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has params => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} }
);

# FIXME:
# Result::links needs to use this
# - SL
sub from_link_header {
    my ($class, $link_header) = @_;
    my ($bucket, $key) = ($link_header->href =~ /^buckets\/(.*)\/keys\/(.*)/);
    my %params = %{ $link_header->params };

    my $riaktag = url_decode( delete $params{'riaktag'} ) if exists $params{'riaktag'};

    $class->new(
        bucket => $bucket,
        key => $key,
        riaktag => $riaktag,
        params => \%params
    );
}


# FIXME:
# Bucket::add needs to use this
# - SL
sub as_link_header {
    my $self = shift;
    HTTP::Headers::ActionPack::LinkHeader->new(
        sprintf('/buckets/%s/keys/%s', $self->bucket, $self->key),
        riaktag => url_encode($self->riaktag),
        %{ $self->params }
    );
}


__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
