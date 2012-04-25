package Data::Riak;

use Moose::Role;

# ABSTRACT: An interface to a Riak server.


=head1 DESCRIPTION

=head1 SYNOPSIS

=begin :prelude

=end :prelude

=cut

requires 'buckets';
requires 'send';

=begin :postlude

=head1 ACKNOWLEDGEMENTS


=end :postlude

=cut

no Moose::Role;

1;

__END__
