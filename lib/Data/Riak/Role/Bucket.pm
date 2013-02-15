package Data::Riak::Role::Bucket;

use Moose::Role;
use namespace::autoclean;

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_linklist {
    my ($self, $links) = @_;

    my $pack = HTTP::Headers::ActionPack::LinkList->new;

    for my $link (@{ $links || [] }) {
        if(blessed $link && $link->isa('Data::Riak::Link')) {
            $pack->add($link->as_link_header);
        }
        else {
            confess "Bad link type ($link)";
        }
    }

    return $pack;
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

1;
