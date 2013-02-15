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

__PACKAGE__->meta->make_immutable;

1;
