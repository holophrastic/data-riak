package Data::Riak::Transport;

use Moose::Role;
use namespace::autoclean;

requires 'send', 'create_request';

1;
