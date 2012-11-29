package Data::Riak::Result::WithLinks;

use Moose::Role;
use Data::Riak::Link;
use namespace::autoclean;

requires 'clone';

has links => (
    is => 'ro',
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
    return $self->clone(links => [@{ $self->links }, $link]);
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
    return $self->clone(links => $new_links);
}

1;
