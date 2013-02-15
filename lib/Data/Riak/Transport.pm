package Data::Riak::Transport;

use Moose::Role;
use namespace::autoclean;

requires 'send', 'create_request', 'base_uri';

1;
