package Data::Riak::Request::StoreObject;

use Moose;
use namespace::autoclean;

has value => (
    is       => 'ro',
    required => 1,
);

has links => (
    is       => 'ro',
    isa      => 'HTTP::Headers::ActionPack::LinkList',
    required => 1,
);

has return_body => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has content_type => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_content_type',
);

has indexes => (
    is        => 'ro',
    isa       => 'ArrayRef',
    predicate => 'has_indexes',
);

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'PUT',
        uri    => sprintf('buckets/%s/keys/%s', $self->bucket_name, $self->key),
        data   => $self->value,
        links  => $self->links,
        ($self->return_body ?
             (query => { returnbody => 'true' })
             : ()),
        ($self->has_content_type
             ? (content_type => $self->content_type) : ()),
        ($self->has_indexes
             ? (indexes => $self->indexes) : ()),
    };
}

with 'Data::Riak::Request::WithObject';

has '+result_class' => (
    default => Data::Riak::Result::Object::,
);

__PACKAGE__->meta->make_immutable;

1;