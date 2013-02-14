package Data::Riak;
# ABSTRACT: An interface to a Riak server.

use Moose;

use Class::Load 'load_class';

use Data::Riak::Result;
use Data::Riak::Result::Object;
use Data::Riak::ResultSet;
use Data::Riak::Bucket;
use Data::Riak::MapReduce;

use Data::Riak::HTTP;

use namespace::autoclean;

=head1 DESCRIPTION

Data::Riak is a simple interface to a Riak server. It is not as complete as
L<Net::Riak>, nor does it aim to be; instead, it attempts to make the simple
operations very simple, while still allowing you to do complicated tasks.

=head1 SYNOPSIS

    my $riak = Data::Riak->new({
        transport => Data::Riak::HTTP->new({
            host => 'riak.example.com',
            port => '8098',
            timeout => 5
        })
    });

    my $bucket = Data::Riak::Bucket->new({
        name => 'my_bucket',
        riak => $riak
    });

    # Sets the value of "foo" to "bar", in my_bucket.
    $bucket->add('foo', 'bar');

    # Gets the Result object for "foo" in my_bucket.
    my $foo = $bucket->get('foo');

    # Returns "bar"
    my $value = $foo->value;

    # The HTTP status code, 200 on a successful GET.
    my $code = $foo->status_code;

Most of the interesting methods are really in L<Data::Riak::Bucket>, so please
read the documents there as well.

=attr transport

A L<Data::Riak::Transport> to be used in order to communicate with
Riak. Currently, the only existing transport is L<Data::Riak::HTTP>.

=cut

has transport => (
    is       => 'ro',
    does     => 'Data::Riak::Transport',
    required => 1,
    handles  => {
        'base_uri' => 'base_uri'
    }
);

has request_classes => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[Str]',
    builder => '_build_request_classes',
    handles => {
        _available_request_classes => 'values',
        request_class_for          => 'get',
        has_request_class_for      => 'exists',
    },
);

sub _build_request_classes {
    return +{
        (map {
            ($_ => 'Data::Riak::Request::' . $_),
        } qw(MapReduce Ping GetBucketProps StoreObject GetObject
             ListBucketKeys RemoveObject LinkWalk Status ListBuckets
             SetBucketProps)),
    }
}

sub BUILD {
    my ($self) = @_;

    load_class $_
        for $self->_available_request_classes;
}

sub _create_request {
    my ($self, $args) = @_;

    my %args_copy = %{ $args };
    my $type = delete $args_copy{type};

    confess sprintf 'Unknown request class %s', $type
        unless $self->has_request_class_for($type);

    return $self->request_class_for($type)->new(\%args_copy);
}

sub send_request {
    my ($self, $request_data) = @_;

    my $request = $self->_create_request($request_data);
    my $response = $self->transport->send($request);

    my @results = $response->create_results($self, $request);
    return unless @results;

    if (@results == 1 && $results[0]->does('Data::Riak::Result::Single')) {
        return $results[0];
    }

    return Data::Riak::ResultSet->new({ results => \@results });
}

=method ping

Tests to see if the specified Riak server is answering. Returns 0 for no, 1 for
yes.

=cut

sub ping {
    my ($self) = @_;
    return $self->send_request({ type => 'Ping' })->status_code == 200 ? 1 : 0;
}

=method status

Attempts to retrieve information about the performance and configuration of the
Riak node. Returns a hash reference containing the data provided by the
C</stats> endpoint of the Riak node or throws an exception if the status
information could not be retrieved.

=cut

sub status {
    my ($self) = @_;
    return $self->send_request({ type => 'Status' })->json_value;
}

=method _buckets

Get the list of buckets. This is NOT RECOMMENDED for production systems, as Riak
has to essentially walk the entire database. Here purely as a tool for debugging
and convenience.

=cut

sub _buckets {
    my $self = shift;
    return $self->send_request({
        type => 'ListBuckets',
    })->json_value->{buckets};
}

=method bucket ($name)

Given a C<$name>, this will return a L<Data::Riak::Bucket> object for it.

=cut

sub bucket {
    my ($self, $bucket_name) = @_;
    return Data::Riak::Bucket->new({
        riak => $self,
        name => $bucket_name
    })
}

sub resolve_link {
    my ($self, $link) = @_;
    $self->bucket( $link->bucket )->get( $link->key );
}

sub linkwalk {
    my ($self, $args) = @_;
    my $object = $args->{object} || confess 'You must have an object to linkwalk';
    my $bucket = $args->{bucket} || confess 'You must have a bucket for the original object to linkwalk';

    return $self->send_request({
        type        => 'LinkWalk',
        bucket_name => $bucket,
        key         => $object,
        params      => $args->{params},
    });
}

=pod

=head1 LINKWALKING

One of Riak's notable features is the ability to easily "linkwalk", or traverse
relationships between objects to return relevant resultsets. The most obvious
use of this is "Show me all of the friends of people Bob is friends with", but
it has great potential, and it's the one thing we tried to make really simple
with Data::Riak.

    # Add bar to the bucket, and list foo as a buddy.
    $bucket->add('bar', 'value of bar', {
      links => [ Data::Riak::Link->new(
        bucket => $bucket_name, riaktag => 'buddy', key =>'foo'
      ) ]
    });

    # Add foo to the bucket, and list both bar and baz as "not a buddy"
    # create the links via the $bucket object and the bucket will be
    # inferred from the context
    $bucket->add('foo', 'value of foo', {
      links => [
        $bucket->create_link(riaktag => 'not a buddy', key =>'bar'),
        $bucket->create_link(riaktag => 'not a buddy', key =>'baz')
      ]
    });

    # Get everyone in my_bucket who foo thinks is not a buddy.
    $walk_results = $bucket->linkwalk('foo', [ [ 'not a buddy', 1 ] ]);

    # Get everyone in my_bucket who baz thinks is a buddy of baz, get the people
    # they list as not a buddy, and only return those.
    $more_walk_results = $bucket->linkwalk(
      'baz', [ [ 'buddy', 0 ], [ 'not a buddy', 1 ] ],
    );

    # You can also linkwalk outside of a bucket. The syntax changes, as such:
    $global_walk_results = $riak->linkwalk({
        bucket => 'my_bucket',
        object => 'foo',
        params => [ [ 'other_bucket', 'buddy', 1 ] ]
    });

The bucket passed in on the riak object's linkwalk is the bucket the original
target is in, and is used as a default if you only pass two options in the
params lists.

=cut

=begin :postlude

=head1 ACKNOWLEDGEMENTS

Influenced heavily by L<Net::Riak>.

I wrote the first pass of Data::Riak, but large sections were
added/fixed/rewritten to not suck by Stevan Little C<< <stevan at cpan.org> >>
and Cory Watson C<< <gphat at cpan.org> >>.

=head1 TODO

Docs, docs, and more docs. The individual modules have a lot of functionality
that needs documented.

=head1 COPYRIGHT & LICENSE

This software is copyright (c) 2012 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.


=end :postlude

=cut

__PACKAGE__->meta->make_immutable;

1;
