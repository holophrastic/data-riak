package Data::Riak::Result;

use strict;
use warnings;

use Moose;

use URL::Encode qw/url_decode/;
use HTTP::Headers::ActionPack::LinkList;

has riak => (
    is => 'ro',
    isa => 'Data::Riak',
    required => 1
);

has location => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->http_message->request->uri->as_string if $self->http_message->can('request');
        return $self->http_message->header('location') || die "Cannot determine location from " . $self->http_message;
    }
);

has bucket_name => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        my @uri_parts = split /\//, $self->location;
        return $uri_parts[$#uri_parts - 2];
    }
);

has name => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        my @uri_parts = split /\//, $self->location;
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
        my $link_header = $self->http_message->header('link');
        return HTTP::Headers::ActionPack::LinkList->new unless $link_header;
        my $links = HTTP::Headers::ActionPack::LinkList->new_from_string( $link_header );
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
    return $bucket->add($self->name, $self->value, $self->links->items);
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
