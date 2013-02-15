package Data::Riak::Async::Bucket;

use Moose;
use JSON 'decode_json';
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
