package Data::Riak;

use Moose::Role;

# ABSTRACT: An interface to a Riak server.

=head1 DESCRIPTION

Data::Riak is a simple interface to a Riak server. It is not as complete as L<Net::Riak>,
nor does it aim to be; instead, it attempts to make the simple operations very simple,
while still allowing you to do complicated tasks.

=head1 SYNOPSIS

    my $riak = Data::Riak::HTTP->new({
        host => 'riak.example.com',
        port => '8098',
        timeout => 5
    });

    my $bucket = Data::Riak::HTTP::Bucket->new({
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
    my $code = $foo->code;

=begin :prelude

=head1 LINKWALKING

One of Riak's notable features is the ability to easily "linkwalk", or traverse
relationships between objects to return relevant resultsets. The most obvious use
of this is "Show me all of the friends of people Bob is friends with", but it has
great potential, and it's the one thing we tried to make really simple with Data::Riak.

    # Add bar to the bucket, and list foo as a buddy.
    $bucket->add('bar', 'value of bar', [{ bucket => $bucket_name, type => 'buddy', target =>'foo' }]);

    # Add baz to the bucket, and list foo as a buddy. It will default to the current bucket if not passed in.
    $bucket->add('baz', 'value of baz', [{ type => 'buddy', target =>'foo' }]);

    # Add foo to the bucket, and list both bar and baz as "not a buddy"
    $bucket->add('foo', 'value of foo', [{ type => 'not a buddy', target =>'bar' }, { type => 'not a buddy', target =>'baz' }]);

    # Get everyone in my_bucket who foo thinks is not a buddy.
    $walk_results = $bucket->linkwalk('foo', [ [ 'not a buddy', 1 ] ]);

    # Get everyone in my_bucket who baz thinks is a buddy of baz, get the people they list as not a buddy, and only return those.
    $more_walk_results = $bucket->linkwalk('baz', [ [ 'buddy', 0 ], [ 'not a buddy', 1 ] ]);

    # You can also linkwalk outside of a bucket. The syntax changes, as such:
    $global_walk_results = $riak->linkwalk({
        bucket => 'my_bucket',
        object => 'foo',
        params => [ [ 'other_bucket', 'buddy', 1 ] ]
    });

The bucket passed in on the riak object's linkwalk is the bucket the original target is in, and is used as a default if you only pass two options in the params lists.

=cut

=end :prelude

=cut

requires 'send';
requires 'linkwalk';

=begin :postlude

=end :postlude

=cut

no Moose::Role;

1;

__END__
