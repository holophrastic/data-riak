package Data::Riak::Request::LinkWalk;

use Moose;
use namespace::autoclean;

has params => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

sub as_http_request_args {
    my ($self) = @_;

    my $params = $self->params;
    my $params_str = '';

    for my $depth (@$params) {
        if(@{ $depth } == 2) {
            unshift @{ $depth }, $self->bucket_name;
        }
        my ($buck, $tag, $keep) = @{$depth};
        $params_str .= "$buck,$tag,$keep/";
    }

    return {
        method => 'GET',
        uri    => sprintf('buckets/%s/keys/%s/%s',
                          $self->bucket_name, $self->key, $params_str),
    };
}

with 'Data::Riak::Request::WithObject';

has '+result_class' => (
    default => Data::Riak::Result::Object::,
);

__PACKAGE__->meta->make_immutable;

1;
