package Data::Riak::Async::Bucket;

use Moose;
use JSON 'decode_json';
use Data::Riak::Async::MapReduce;
use namespace::autoclean;

with 'Data::Riak::Role::Bucket';

sub remove_all {
    my ($self, $opts) = @_;

    my ($cb, $error_cb) = map { $opts->{$_} } qw(cb error_cb);
    $self->list_keys({
        error_cb => $error_cb,
        cb       => sub { # TODO: retval mangler?
            my ($keys) = @_;
            return $cb->() unless ref $keys eq 'ARRAY' && @$keys;

            my %keys = map { ($_ => 1) } @{ $keys };
            for my $key (@{ $keys }) {
                $self->remove($key, {
                    error_cb => $error_cb,
                    cb       => sub {
                        delete $keys{$key};
                        $cb->() if !keys %keys;
                    },
                });
            }
        },
    });

    return;
}

sub search_index {
    my ($self, $opts) = @_;
    my $field  = $opts->{'field'}  || confess 'You must specify a field for searching Secondary indexes';
    my $values = $opts->{'values'} || confess 'You must specify values for searching Secondary indexes';

    my $inputs = { bucket => $self->name, index => $field };
    if(ref($values) eq 'ARRAY') {
        $inputs->{'start'} = $values->[0];
        $inputs->{'end'} = $values->[1];
    } else {
        $inputs->{'key'} = $values;
    }

    my $search_mr = Data::Riak::Async::MapReduce->new({
        riak => $self->riak,
        inputs => $inputs,
        phases => [
            Data::Riak::MapReduce::Phase::Reduce->new({
                language => 'erlang',
                module => 'riak_kv_mapreduce',
                function => 'reduce_identity',
                keep => 1
            })
        ]
    });

    $search_mr->mapreduce(
        %{ $opts },
        # TODO: retval mangler
        cb       => sub { $opts->{cb}->(shift->results->[0]->value) },
    );

    return;
}

sub pretty_search_index {
    my ($self, $opts) = @_;

    my $cb = delete $opts->{cb};

    $self->search_index({
        %{ $opts },
        cb => sub { # TODO: retval mangler
            $cb->([sort map { $_->[1] } @{ decode_json shift }]);
        },
    });
}

__PACKAGE__->meta->make_immutable;

1;
