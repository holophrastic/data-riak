package Data::Riak::MapReduce;

use strict;
use warnings;

use Moose;

use JSON::XS;

use Data::Riak::Types qw/Riak/;

use Data::Riak::HTTP;
use Data::Riak::MapReduce::MapReduceComponent;

has riak => (
    is => 'ro',
    isa => 'Riak',
    lazy => 1,
    default => sub { {
        my $riak = Data::Riak::HTTP->new;
        return $riak;
    } }
);

has config => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    default => sub { {
        my $self = shift;
        return {};
    } }
);

has map => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {
        my $self = shift;
        return {};
    } }
);

has reduce => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {
        my $self = shift;
        return {};
    } }
);

has link => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {
        my $self = shift;
        return {};
    } }
);

has inputs => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { {
        return [];
    } }
);

sub mapreduce {
    my ($self, $raw_query) = @_;

    my $uri = "mapred";
    $uri .= "?chunked=true" if($self->config->{chunked});

    my $query = {};
    my $data = {};
    $data->{inputs} = $self->inputs;
    $query->{query}->{map} = $self->map if($self->map);
    $query->{query}->{reduce} = $self->reduce if($self->reduce);
    #$query->{query}->{link} = $self->link if($self->link);
    push @{$data->{query}}, $query;
    #Data::Riak::HTTP::MapReduce::MapReduceComponent->new($raw_query->{map})->block if($raw_query->{map});
    #$query->{query}->{reduce} = Data::Riak::HTTP::MapReduce::MapReduceComponent->new($raw_query->{reduce})->block if($raw_query->{reduce});
    #$query->{query}->{link} = $raw_query->{link} if($raw_query->{link});

    my $request = Data::Riak::HTTP::Request->new({
        content_type => 'application/json',
        method => 'POST',
        uri => $uri,
#        data => $query
        data => encode_json($data),
        namespace => ''
    });
    return $self->riak->send($request);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
