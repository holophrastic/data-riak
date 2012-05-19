package Data::Riak;
# ABSTRACT: An interface to a Riak server.

use strict;
use warnings;

use Moose;

use JSON::XS qw/decode_json/;

use Data::Riak::Result;
use Data::Riak::ResultSet;
use Data::Riak::Bucket;
use Data::Riak::MapReduce;

use Data::Riak::HTTP;

=head1 DESCRIPTION

Data::Riak is a simple interface to a Riak server. It is not as complete as L<Net::Riak>,
nor does it aim to be; instead, it attempts to make the simple operations very simple,
while still allowing you to do complicated tasks.

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
    my $code = $foo->code;

=begin :prelude

=cut

has transport => (
    is => 'ro',
    isa => 'Data::Riak::HTTP',
    required => 1,
    handles => {
        'ping' => 'ping',
        'base_uri' => 'base_uri'
    }
);

sub send_request {
    my ($self, $request) = @_;

    my $response = $self->transport->send($request);

    if ($response->is_error) {
        die $response;
    }

    my @parts = @{ $response->parts };

    return unless @parts;
    return Data::Riak::ResultSet->new({
        results => [
            map {
                Data::Riak::Result->new({ riak => $self, http_message => $_ })
            } @parts
        ]
    });
}

=method _buckets

Get the list of buckets. This is NOT RECOMMENDED for production systems, as Riak
has to essentially walk the entire database. Here purely as a tool for debugging
and convenience.

=cut

sub _buckets {
    my $self = shift;
    return decode_json(
        $self->send_request({
            method => 'GET',
            uri => '/buckets',
            query => { buckets => 'true' }
        })->first->value
    );
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
    my $object = $args->{object} || die 'You must have an object to linkwalk';
    my $bucket = $args->{bucket} || die 'You must have a bucket for the original object to linkwalk';

    my $request_str = "buckets/$bucket/keys/$object/";
    my $params = $args->{params};

    foreach my $depth (@$params) {
        if(scalar @{$depth} == 2) {
            unshift @{$depth}, $bucket;
        }
        my ($buck, $tag, $keep) = @{$depth};
        $request_str .= "$buck,$tag,$keep/";
    }

    return $self->send_request({
        method => 'GET',
        uri => $request_str
    });
}

=pod

=head1 LINKWALKING

One of Riak's notable features is the ability to easily "linkwalk", or traverse
relationships between objects to return relevant resultsets. The most obvious use
of this is "Show me all of the friends of people Bob is friends with", but it has
great potential, and it's the one thing we tried to make really simple with Data::Riak.

    # Add bar to the bucket, and list foo as a buddy.
    $bucket->add('bar', 'value of bar', [{ bucket => $bucket_name, riaktag => 'buddy', key =>'foo' }]);

    # Add baz to the bucket, and list foo as a buddy. It will default to the current bucket if not passed in.
    $bucket->add('baz', 'value of baz', [{ riaktag => 'buddy', key =>'foo' }]);

    # Add foo to the bucket, and list both bar and baz as "not a buddy"
    $bucket->add('foo', 'value of foo', [{ riaktag => 'not a buddy', key =>'bar' }, { riaktag => 'not a buddy', key =>'baz' }]);

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

=begin :postlude

=head1 ACKNOWLEDGEMENTS


=end :postlude

=cut

__PACKAGE__->meta->make_immutable;
no Moose;

1;
