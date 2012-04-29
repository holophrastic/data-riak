package Data::Riak::Types;

use strict;
use warnings;

use MooseX::Types::Moose qw/Str Int ArrayRef HashRef/;
use MooseX::Types -declare => [ qw/HTTPMessage HTTPResponse HTTPRequest HTTPHeadersActionPack HTTPHeadersActionPackLinkList Riak RiakResult/ ];

class_type 'HTTPMessage', { class => 'HTTP::Message' };
class_type 'HTTPResponse', { class => 'HTTP::Response' };
class_type 'HTTPRequest', { class => 'HTTP::Request' };

class_type 'HTTPHeadersActionPack', { class => 'HTTP::Headers::ActionPack' };
class_type 'HTTPHeadersActionPackLinkList', { class => 'HTTP::Headers::ActionPack::LinkList' };

class_type 'Riak', { class => 'Data::Riak::HTTP' };
class_type 'RiakResult', { class => 'Data::Riak::HTTP::Result' };

1;

__END__
