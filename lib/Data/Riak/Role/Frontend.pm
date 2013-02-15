package Data::Riak::Role::Frontend;

use Moose::Role;
use Class::Load 'load_class';
use namespace::autoclean;

has transport => (
    is       => 'ro',
    does     => 'Data::Riak::Transport',
    required => 1,
    handles  => {
        base_uri => 'base_uri'
    }
);

has request_classes => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[Str]',
    builder => '_build_request_classes',
    handles => {
        _available_request_classes => 'values',
        request_class_for          => 'get',
        has_request_class_for      => 'exists',
    },
);

has bucket_class => (
    is      => 'ro',
    isa     => 'ClassName',
    builder => '_build_bucket_class',
    handles => {
        _new_bucket => 'new',
    },
);

sub BUILD {}
after BUILD => sub {
    my ($self) = @_;

    load_class $_
        for $self->_available_request_classes;
};

sub _create_request {
    my ($self, $args) = @_;

    my %args_copy = %{ $args };
    my $type = delete $args_copy{type};

    confess sprintf 'Unknown request class %s', $type
        unless $self->has_request_class_for($type);

    return $self->request_class_for($type)->new(\%args_copy);
}

sub bucket {
    my ($self, $bucket_name) = @_;
    return $self->_new_bucket({
        riak => $self,
        name => $bucket_name,
    });
}

1;
