package Data::Riak::Result;
# ABSTRACT: A result of a Riak query

use Moose;
use MooseX::StrictConstructor;

with 'Data::Riak::Role::HasRiak';

=head1 SYNOPSIS

  my $result = $bucket->get('key');
  $result->value;

=head1 DESCRIPTION

This class represents the result of a query to Riak.

Note that different kinds of requests can result in different kinds of
results. For a listing of different request kinds and their corresponding result
classes, see L<Data::Riak::Request>. This document only describes attributes
common to all result classes.

=attr status_code

A code describing the result of the query that produced this result. Currently
this is an HTTP status code.

=cut

has status_code => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

=attr content_type

The result's content type.

=cut

has content_type => (
    is       => 'ro',
    isa      => 'HTTP::Headers::ActionPack::MediaType',
    required => 1,
);

=attr

The result's value.

=cut

has value => (
    is  => 'ro',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
