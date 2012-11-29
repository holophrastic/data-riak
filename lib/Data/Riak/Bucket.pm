package Data::Riak::Bucket;
# ABSTRACT: A Data::Riak bucket, used for storing keys and values.

use strict;
use warnings;

use Moose;

use Data::Riak::Link;
use Data::Riak::Util::MapCount;
use Data::Riak::Util::ReduceCount;
use Data::Riak::Result;
use Data::Riak::Result::Object;

use Data::Riak::MapReduce;
use Data::Riak::MapReduce::Phase::Reduce;

use HTTP::Headers::ActionPack::LinkList;

use JSON::XS qw/decode_json encode_json/;

use namespace::autoclean;

with 'Data::Riak::Role::HasRiak';

=head1 DESCRIPTION

Data::Riak::Bucket is the primary interface that most people will use for Riak.
Adding and removing keys and values, adding links, querying keys; all of those
happen here.

=head SYNOPSIS

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

    $bucket->create_alias({ key => 'foo', as => 'alias_to_foo' });
    $bucket->create_alias({ key => 'foo', as => 'alias_to_foo', in => $another_bucket });

    # Returns "bar"
    my $value = $bucket->resolve_alias('alias_to_foo');
    my $value = $another_bucket->resolve_alias('alias_to_foo');

    $bucket->add('baz, 'value of baz', { links => [$bucket->create_link( riaktag => 'buddy', key =>'foo' )] });
    my $resultset = $bucket->linkwalk('baz', [[ 'buddy', '_' ]]);
    my $value = $resultset->first->value;   # Will be "bar", the value of foo

=cut

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

=method add ($key, $value, $opts)

This will insert a key C<$key> into the bucket, with value C<$value>. The C<$opts>
can include links, allowed content types, or queries.

=cut

sub add {
    my ($self, $key, $value, $opts) = @_;

    $opts ||= {};

    my $pack = HTTP::Headers::ActionPack::LinkList->new;
    if($opts->{'links'}) {
        foreach my $link (@{$opts->{'links'}}) {
            if(blessed $link && $link->isa('Data::Riak::Link')) {
                $pack->add($link->as_link_header);
            }
            else {
                confess "Bad link type ($link)";
            }
        }
    }

    # TODO:
    # need to support other headers
    #   X-Riak-Vclock if the object already exists, the vector clock attached to the object when read.
    #   X-Riak-Meta-* - any additional metadata headers that should be stored with the object.
    # see http://wiki.basho.com/HTTP-Store-Object.html
    # - SL

    return $self->riak->send_request({
        type        => 'StoreObject',
        bucket_name => $self->name,
        key         => $key,
        value       => $value,
        links       => $pack,
        return_body => $opts->{return_body},
        (exists $opts->{content_type}
             ? (content_type => $opts->{content_type}) : ()),
        (exists $opts->{indexes}
             ? (indexes => $opts->{indexes}) : ()),
    });
}

=method remove ($key, $opts)

This will remove a key C<$key> from the bucket.

=cut

sub remove {
    my ($self, $key, $opts) = @_;

    $opts ||= {};

    return $self->riak->send_request({
        type        => 'RemoveObject',
        bucket_name => $self->name,
        key         => $key,
        (exists $opts->{'query'}
            ? (query => $opts->{'query'})
            : ()),
    });
}

=method get ($key, $opts)

This will get a key C<$key> from the bucket, returning a L<Data::Riak::Result> object.

=cut


sub get {
    my ($self, $key, $opts) = @_;

    confess "This method requires a key" unless $key;

    $opts ||= {};

    confess "This method does not support multipart/mixed responses"
        if exists $opts->{'accept'} && $opts->{'accept'} eq 'multipart/mixed';

    return $self->riak->send_request({
        type        => 'GetObject',
        bucket_name => $self->name,
        key         => $key,
        (exists $opts->{'accept'}
            ? (accept => $opts->{'accept'})
            : ()),
        (exists $opts->{'query'}
            ? (query => $opts->{'query'})
            : ()),
    });
}

=method list_keys

List all the keys in the bucket. Warning: This is expensive, as it has to scan
every key in the system, so don't use it unless you mean it, and know what you're
doing.

=cut


sub list_keys {
    my $self = shift;

    return $self->riak->send_request({
        type        => 'ListBucketKeys',
        bucket_name => $self->name,
    })->json_value->{keys};
}

=method count

Count all the keys in a bucket. This uses MapReduce to figure out the answer, so
it's expensive; Riak does not keep metadata on buckets for reasons that are beyond
the scope of this module (but are well documented, so if you are interested, read up).

=cut

sub count {
    my $self = shift;
    my $map_reduce = Data::Riak::MapReduce->new({
        riak => $self->riak,
        inputs => $self->name,
        phases => [
            Data::Riak::Util::MapCount->new,
            Data::Riak::Util::ReduceCount->new
        ]
    });
    my $map_reduce_results = $map_reduce->mapreduce;
    my ( $result ) = $map_reduce_results->results->[0];
    my ( $count ) = decode_json($result->value) || 0;
    return $count->[0];
}

=method remove_all

Remove all the keys from a bucket. This involves a list_keys call, so it will be
slow on larger systems.

=cut

sub remove_all {
    my $self = shift;
    my $keys = $self->list_keys;
    return unless ref $keys eq 'ARRAY' && @$keys;
    foreach my $key ( @$keys ) {
        $self->remove( $key );
    }
}

sub create_link {
    my $self = shift;
    my %opts = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    confess "You must provide a key for a link" unless exists $opts{key};
    confess "You must provide a riaktag for a link" unless exists $opts{riaktag};
    return Data::Riak::Link->new({
        bucket => $self->name,
        key => $opts{key},
        riaktag => $opts{riaktag},
        (exists $opts{params} ? (params => $opts{params}) : ())
    });
}

sub linkwalk {
    my ($self, $object, $params) = @_;
    return undef unless $params;
    return $self->riak->linkwalk({
        bucket => $self->name,
        object => $object,
        params => $params
    });
}

=method search_index

Searches a Secondary Index to find results.

=cut

sub search_index {
    my ($self, $opts) = @_;
    my $field  = $opts->{'field'}  || confess 'You must specify a field for searching Secondary indexes';
    my $values = $opts->{'values'} || confess 'You must specify values for searching Secondary indexes';

    my $inputs = { bucket => $self->name, index => $field };
    if(ref($values) eq 'ARRAY') {
        $inputs->{'start'} = $values->[0];
        $inputs->{'end'} = $values->[1];
    } else {
        $inputs->{'key'} = $values;
    }

    my $search_mr = Data::Riak::MapReduce->new({
        riak => $self->riak,
        inputs => $inputs,
        phases => [
            Data::Riak::MapReduce::Phase::Reduce->new({
                language => 'erlang',
                module => 'riak_kv_mapreduce',
                function => 'reduce_identity',
                keep => 1
            })
        ]
    });
    return $search_mr->mapreduce->results->[0]->value;
}

# returns JUST the list of keys. human readable, not designed for MapReduce inputs.
sub pretty_search_index {
    my ($self, $opts) = @_;
    return [ sort map { $_->[1] } @{decode_json($self->search_index($opts))} ];
}

sub props {
    my $self = shift;

    return $self->riak->send_request({
        type        => 'GetBucketProps',
        bucket_name => $self->name,
    })->json_value->{props};
}

sub indexing {
    my ($self, $enable) = @_;

    my $data;

    if($enable) {
        $data->{props}->{precommit}->{mod} = 'riak_search_kv_hook';
        $data->{props}->{precommit}->{fun} = 'precommit';
    } else {
        $data->{props}->{precommit}->{mod} = undef;
        $data->{props}->{precommit}->{fun} = undef;
    };

    return $self->riak->send_request({
        type        => 'SetBucketProps',
        bucket_name => $self->name,
        props       => $data,
    });
}

=method create_alias ($opts)

Creates an alias for a record using links. Helpful if your primary ID is a UUID or
some other automatically generated identifier. Can cross buckets, as well.

    $bucket->create_alias({ key => '123456', as => 'foo' });
    $bucket->create_alias({ key => '123456', as => 'foo', in => $other_bucket });

=cut

sub create_alias {
    my ($self, $opts) = @_;
    my $bucket = $opts->{in} || $self;
    $bucket->add($opts->{as}, $opts->{key}, { links => [ Data::Riak::Link->new( bucket => $bucket->name, riaktag => 'perl-data-riak-alias', key => $opts->{key} )] });
}

=method resolve_alias ($alias)

Returns the L<Data::Riak::Result> that $alias points to.

=cut

sub resolve_alias {
    my ($self, $alias) = @_;
    return $self->linkwalk($alias, [[ 'perl-data-riak-alias', '_' ]])->first;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
