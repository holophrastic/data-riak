package Data::Riak::Transport::Response;

use Moose::Role;
use namespace::autoclean;

requires qw(is_error parts);

1;
