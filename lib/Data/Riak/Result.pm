package Data::Riak::Result;

use strict;
use warnings;

use Moose;

use Data::Riak::Link;

use URI;
use HTTP::Headers::ActionPack 0.05;

with 'Data::Riak::Role::HasRiak';

has bucket => (
    is => 'ro',
    isa => 'Data::Riak::Bucket',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->riak->bucket( $self->bucket_name )
    }
);

has links => (
    is => 'rw',
    isa => 'ArrayRef[Data::Riak::Link]',
);

has [qw(status_code etag content_type vector_clock last_modified)] => (
    is => 'ro',
);

has value => (
    is  => 'rw', # for ->save
    isa => 'Str',
);

sub create_link {
    my ($self, %opts) = @_;
    return Data::Riak::Link->new({
        bucket => $self->bucket_name,
        key => $self->key,
        riaktag => $opts{riaktag},
        (exists $opts{params} ? (params => $opts{params}) : ())
    });
}

# if it's been changed on the server, discard those changes and update the object
sub sync {
    $_[0] = $_[0]->bucket->get($_[0]->key)
}

# if it's been changed locally, save those changes to the server
sub save {
    my $self = shift;
    return $self->bucket->add($self->key, $self->value, { links => $self->links });
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

sub add_link {
    my ($self, $link) = @_;
    return undef unless $link;
    my $links = $self->links;
    push @{$links}, $link;
    $self->links($links);
    return $self;
}

sub remove_link {
    my ($self, $args) = @_;
    my $key = $args->{key};
    my $riaktag = $args->{riaktag};
    my $bucket = $args->{bucket};
    my $links = $self->links;
    my $new_links;
    foreach my $link (@{$links}) {
        next if($bucket && ($bucket eq $link->bucket));
        next if($key && $link->has_key && ($key eq $link->key));
        next if($riaktag && $link->has_riaktag && ($riaktag eq $link->riaktag));
        push @{$new_links}, $link;
    }
    $self->links($new_links);
    return $self;
}


__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
