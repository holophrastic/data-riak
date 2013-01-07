package Data::Riak::Result::WithLocation;

use Moose::Role;
use namespace::autoclean;

has location => (
    is       => 'ro',
    isa      => 'URI',
    required => 1,
);

has bucket => (
    is      => 'ro',
    isa     => 'Data::Riak::Bucket',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->riak->bucket( $self->bucket_name )
    }
);

has bucket_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @uri_parts = split /\//, $self->location->path;
        return $uri_parts[$#uri_parts - 2];
    }
);

has key => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @uri_parts = split /\//, $self->location->path;
        return $uri_parts[$#uri_parts];
    }
);

sub BUILD {}
after BUILD => sub {
    my ($self) = @_;
    $self->bucket_name;
    $self->key;
};

# if it's been changed on the server, discard those changes and update the
# object
my %warned_for;
sub sync {
    my ($self) = @_;

    my $new_result = $self->bucket->get( $self->key );
    if (!defined wantarray) {
        my $caller = caller;
        warn "${caller} is using the deprecated ->sync in void context"
            unless $warned_for{$caller};
        $_[0] = $new_result;
    }

    return $new_result;
}

# if it's been changed locally by cloning, save those changes to the server
sub save {
    my ($self, %opts) = @_;
    return $self->bucket->add(
        $self->key, (exists $opts{new_value} ? $opts{new_value} : $self->value),
        {
            links => (exists $opts{new_links} ? $opts{new_links} : $self->links),
            return_body  => 1,
            vector_clock => $self->vector_clock,
        },
    );
}

sub save_unless_modified {
    my ($self, %opts) = @_;
    return $self->bucket->add(
        $self->key, (exists $opts{new_value} ? $opts{new_value} : $self->value),
        {
            links => (exists $opts{new_links} ? $opts{new_links} : $self->links),
            return_body  => 1,
            vector_clock => $self->vector_clock,
            if_unmodified_since => $self->last_modified . '',
            if_match => $self->etag,
        },
    );
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

1;
