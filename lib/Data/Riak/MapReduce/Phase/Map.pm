package Data::Riak::MapReduce::Phase::Map;
use Moose;
use Moose::Util::TypeConstraints;

use JSON::XS ();

# ABSTRACT: Map phase of a MapReduce

with ('Data::Riak::MapReduce::Phase');

=head1 DESCRIPTION

A map/reduce map phase for Data::Riak

=head1 SYNOPSIS

  my $mp = Data::Riak::MapReduce::Phase::Map->new(
    language => "javascript", # The default
    source => "function(v) { return [ v ] }",
    keep => 1 # The default
  );

=attr keep

Flag controlling whether the results of this phase are included in the final
result of the map/reduce. Defaults to true.

=attr language

The language used with this phase.  One of C<javascript> or C<erlang>. This
attribute is required.

=cut

has language => (
  is => 'ro',
  isa => enum([qw(javascript erlang)]),
  required => 1
);

=attr name

The name, used with built-in functions provided by Riak such as
C<Riak.mapValues>.

=cut

has name => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_name'
);

has phase => (
  is => 'ro',
  isa => 'Str',
  default => 'map'
);

=attr source

The source of the function used in this phase.

=cut

has source => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_source'
);

=method pack

Serialize this map phase.

=cut

sub pack {
  my $self = shift;

  my $href = {};

  $href->{keep} = $self->keep ? JSON::XS::true() : JSON::XS::false() if $self->has_keep;
  $href->{language} = $self->language;
  $href->{name} = $self->name if $self->has_name;
  $href->{source} = $self->source if $self->has_source;

  $href;
}

1;