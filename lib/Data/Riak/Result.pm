package Data::Riak::Result;

use strict;
use warnings;

use Moose;

has riak => (
    is => 'ro',
    isa => 'Data::Riak',
    required => 1
);

has bucket_name => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        my @uri_parts = split /\//, $self->http_message->request->uri;
        return $uri_parts[$#uri_parts - 2];
    }
);

has name => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        my @uri_parts = split /\//, $self->http_message->request->uri;
        return $uri_parts[$#uri_parts];
    }
);


has links => (
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    clearer => '_clear_links',
    default => sub { '' }
);

has http_message => (
    is => 'rw',
    isa => 'HTTP::Message',
    required => 1,
    handles => {
        'code'  => 'code',
        'value' => 'content'
    }
);

# if it's been changed on the server, discard those changes and update the object
sub sync {
    my $self = shift;
    my $bucket = Data::Riak::Bucket->new({
        name => $self->bucket_name,
        riak => $self->riak
    });
    my $new = $bucket->get($self->name);
    $self->http_message($new->http_message);

    # and clear any of the attributes that got inflated already
    $self->_clear_links;
}

# if it's been changed locally, save those changes to the server
sub save {
    my $self = shift;
    my $bucket = Data::Riak::Bucket->new({
        name => $self->bucket_name,
        riak => $self->riak
    });
    return $bucket->add($self->name, $self->value, $self->links);
}

sub linkwalk {
    my ($self, $params) = @_;
    return undef unless $params;
    return $self->riak->linkwalk({
        bucket => $self->bucket_name,
        object => $self->name,
        params => $params
    });
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
