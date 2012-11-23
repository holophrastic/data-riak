package Data::Riak::MapReduce::Phase::Link;
use Moose;

use JSON::XS ();
use namespace::autoclean;

# ABSTRACT: Link phase of a MapReduce

with ('Data::Riak::MapReduce::Phase');

=head1 DESCRIPTION

A map/reduce link phase for Data::Riak

=head1 SYNOPSIS

  my $lp = Data::Riak::MapReduce::Phase::Link->new(
    bucket=> "foo",
    tag   => "friend",
    keep  => 0
  );

=attr bucket

The name of the bucket from which links should be followed.

=cut

has bucket => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_bucket'
);

has phase => (
    is => 'ro',
    isa => 'Str',
    default => 'link'
);

=attr tag

The name of the tag of links that should be followed

=cut

has tag => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_tag'
);

=method pack

Serialize this link phase.

=cut

sub pack {
    my $self = shift;

    my $href = {};

    $href->{keep} = $self->keep ? JSON::XS::true() : JSON::XS::false() if $self->has_keep;
    $href->{bucket} = $self->bucket if $self->has_bucket;
    $href->{tag} = $self->tag if $self->has_tag;

    $href;
}

1;
