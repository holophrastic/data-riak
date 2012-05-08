package Data::Riak::MapReduce::MapReduceComponent;

use strict;
use warnings;

use Moose;
use JSON::XS;

has language => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has source => (
    is => 'ro',
    isa => 'Str'
);

has arg => (
    is => 'ro',
    isa => 'Str'
);

has bucket => (
    is => 'ro',
    isa => 'Str'
);

has key => (
    is => 'ro',
    isa => 'Str'
);

has keep => (
    is => 'ro',
    isa => 'Int'
);

has module => (
    is => 'ro',
    isa => 'Str'
);

has function => (
    is => 'ro',
    isa => 'Str'
);

has block => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    builder => '_build_block'
);

sub _build_block {
    my $self = shift;

    my $keep;
    if(defined($self->keep)) {
        $keep = $self->keep ? JSON::XS::true : JSON::XS::false;
    }

    if($self->source) {
        # all it needs is source to be valid
        return {
            language => $self->language,
            source => $self->source,
            keep => $keep
        };
    }

    if($self->bucket) {
        # We have a bucket, so we need a key.
        die 'Can not specify a bucket without a key' unless($self->key);
        return {
            language => $self->language,
            bucket => $self->bucket,
            key => $self->key,
            keep => $keep
        };
    }

    if($self->module) {
        # We have a module, so we need a function.
        die 'Can not specify a module without a function' unless($self->function);
        return {
            language => $self->language,
            function => $self->function,
            module => $self->module,
            keep => $keep
        };
    }

    die 'A mapreduce block needs either a module, a bucket, or raw source.';
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
