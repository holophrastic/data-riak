package Data::Riak::Result::WithLinks;

use Moose::Role;
use Data::Riak::Link;
use namespace::autoclean;

has links => (
    is => 'rw',
    isa => 'ArrayRef[Data::Riak::Link]',
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

1;
