package Data::Riak::HTTP::Result;

use strict;
use warnings;

use Moose;

has riak => (
    is => 'ro',
    isa => 'Riak',
    lazy => 1,
    default => sub { {
        my $self = shift;
        my @uri_parts = split /\//, $self->http_message->request->uri;
        my @loc_parts = split /\:/, $uri_parts[2];

        return Data::Riak::HTTP->new({
            host => $loc_parts[0],
            port => $loc_parts[1]
        });
    } }
);

has bucket_name => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub { {
        my $self = shift;
        my @uri_parts = split /\//, $self->http_message->request->uri;
        return $uri_parts[$#uri_parts - 1];
    } }
);

has name => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub { {
        my $self = shift;
        my @uri_parts = split /\//, $self->http_message->request->uri;
        return $uri_parts[$#uri_parts];
    } }
);

has value => (
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    clearer => '_clear_value',
    default => sub { {
        my $self = shift;
        return $self->http_message->content;
    } }
);

has code => (
    is => 'ro',
    isa => 'Int',
    lazy => 1,
    clearer => '_clear_code',
    default => sub { {
        my $self = shift;
        return $self->http_message->code;
    } }
);


has links => (
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    clearer => '_clear_links',
    default => sub { {
        return  '';
    } }
);

has http_message => (
    is => 'rw',
    isa => 'HTTPMessage',
    required => 1
);

# if it's been changed on the server, discard those changes and update the object
sub sync {
    my $self = shift;
    my $bucket = Data::Riak::HTTP::Bucket->new({
        name => $self->bucket_name,
        riak => $self->riak
    });
    my $new = $bucket->get($self->name);
    $self->http_message($new->http_message);

    # and clear any of the attributes that got inflated already
    $self->_clear_lazy;
}

# if it's been changed locally, save those changes to the server
sub save {
    my $self = shift;
    my $bucket = Data::Riak::HTTP::Bucket->new({
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

sub _clear_lazy {
    my $self = shift;
    $self->_clear_code;
    $self->_clear_links;
    $self->_clear_value;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
