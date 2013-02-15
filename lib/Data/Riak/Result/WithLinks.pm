package Data::Riak::Result::WithLinks;
# ABSTRACT: Results with links

use Moose::Role;
use Data::Riak::Link;
use namespace::autoclean;

with 'MooseX::Clone';

=attr links

This object's list of L<Data::Riak::Link>s.

=cut

has links => (
    is  => 'ro',
    isa => 'ArrayRef[Data::Riak::Link]',
);

=method create_link

  my $link = $obj->create_link(
      riaktag => 'buddy',
  );

Create a new L<Data::Riak::Link> for this object's key within its bucket.

This only instanciates a new link. It won't automatically be added to the
object's list of links. Use L</add_link> for that.

=cut

sub create_link {
    my ($self, %opts) = @_;
    return Data::Riak::Link->new({
        bucket => $self->bucket_name,
        key => $self->key,
        riaktag => $opts{riaktag},
        (exists $opts{params} ? (params => $opts{params}) : ())
    });
}

=method add_link

  my $obj_with_links = $obj->add_link(
      $obj->create_link(riaktag => 'buddy'),
  );

Returns a clone of the instance, with the new link added to its list of links.

=cut

sub add_link {
    my ($self, $link) = @_;
    confess 'No link to add provided'
        unless blessed $link && $link->isa('Data::Riak::Link');
    return $self->clone(links => [@{ $self->links }, $link]);
}

=method remove_link

=cut

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
