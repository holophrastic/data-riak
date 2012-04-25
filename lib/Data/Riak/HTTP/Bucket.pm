package Data::Riak::HTTP::Bucket;

use strict;
use warnings;

use Data::Dump;

use Moose;

has riak => (
    is => 'ro',
    isa => 'Data::Riak::HTTP',
    default => sub { {
        return Data::Riak::HTTP->new;
    } }
);

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

sub add {
    my ($self, $key, $value, $links) = @_;

    my $processed_links = [];
    if($links) {
        foreach my $link (@{$links}) {
            push @{$processed_links}, sprintf('</riak/%s/%s>; riaktag="%s"',
                $link->{bucket} || $self->name,
                $link->{link_target},
                $link->{link_type});
        }
    }

    my $request = Data::Riak::HTTP::Request->new({
        method => 'PUT',
        uri => sprintf('%s/%s', $self->name, $key),
        data => $value,
        links => $processed_links
    });
    return $self->riak->send($request);
}

sub remove {
    my ($self, $key) = @_;
    my $request = Data::Riak::HTTP::Request->new({
        method => 'DELETE',
        uri => sprintf('%s/%s', $self->name, $key)
    });
    return $self->riak->send($request);
}

sub get {
    my ($self, $key) = @_;
    my $request = Data::Riak::HTTP::Request->new({
        method => 'GET',
        uri => sprintf('%s/%s', $self->name, $key)
    });
    return $self->riak->send($request);
}

sub linkwalk {
    my ($self, $object, $params) = @_;
    return undef unless $params;
    return $self->riak->linkwalk({
        bucket => $self->name,
        object => $object,
        params => $params
    });
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
