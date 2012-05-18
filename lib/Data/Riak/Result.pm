package Data::Riak::Result;

use strict;
use warnings;

use Moose;

use URI;
use URL::Encode qw/url_decode/;
use HTTP::Headers::ActionPack::LinkList;

with 'Data::Riak::Role::HasRiak';

has bucket => (
    is => 'ro',
    isa => 'Data::Riak::Bucket',
    lazy => 1,
    default => sub {
        my $self = shift;
        return Data::Riak::Bucket->new({
            name => $self->bucket_name,
            riak => $self->riak
        });
    }
);

has location => (
    is => 'ro',
    isa => 'URI',
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->http_message->request->uri if $self->http_message->can('request');
        return URI->new( $self->http_message->header('location') || die "Cannot determine location from " . $self->http_message );
    }
);

has bucket_name => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        my @uri_parts = split /\//, $self->location->path;
        return $uri_parts[$#uri_parts - 2];
    }
);

has key => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        my @uri_parts = split /\//, $self->location->path;
        return $uri_parts[$#uri_parts];
    }
);

has links => (
    is => 'rw',
    isa => 'HTTP::Headers::ActionPack::LinkList',
    lazy => 1,
    clearer => '_clear_links',
    default => sub {
        my $self = shift;
        my $links = $self->http_message->header('link');
        return HTTP::Headers::ActionPack::LinkList->new unless $links;
        # NOTE:
        # we do the inverse of this in
        # &Data::Riak::Bucket::add
        # - SL
        foreach my $link ( $links->iterable ) {
            $link->params->{'riaktag'} = url_decode( $link->params->{'riaktag'} )
                if exists $link->params->{'riaktag'};
        }
        return $links;
    }
);

has http_message => (
    is => 'rw',
    isa => 'HTTP::Message',
    required => 1,
    handles => {
        'status_code' => 'code',
        'value' => 'content',
        'header' => 'header',
        'headers' => 'headers',
        # curried delegation
        'content_type' => [ 'header' => 'content-type' ],
        'vector_clock' => [ 'header' => 'x-riak-vclock' ],
        'etag' => [ 'header' => 'etag' ],
        'last_modified' => [ 'header' => 'last_modified' ]
    }
);

sub BUILD {
    my $self = shift;
    HTTP::Headers::ActionPack->new->inflate( $self->http_message->headers );
}

sub create_link {
    my ($self, %opts) = @_;
    return { bucket => $self->bucket_name, key => $self->key, %opts };
}

# if it's been changed on the server, discard those changes and update the object
sub sync {
    my $self = shift;

    # TODO:
    # need to check here for 304 responses
    # http://wiki.basho.com/HTTP-Fetch-Object.html
    # once we add in conditional fetching
    # - SL
    my $new = $self->bucket->get($self->key);
    $self->http_message($new->http_message);

    # and clear any of the attributes that got inflated already
    $self->_clear_links;
}

# if it's been changed locally, save those changes to the server
sub save {
    my $self = shift;
    return $self->bucket->add($self->key, $self->value, { links => $self->links->items });
}

sub linkwalk {
    my ($self, $params) = @_;
    return undef unless $params;
    return $self->riak->linkwalk({
        bucket => $self->bucket_name,
        object => $self->key,
        params => $params
    });
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
