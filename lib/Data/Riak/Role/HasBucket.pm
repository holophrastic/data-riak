package Data::Riak::Role::HasBucket;

use strict;
use warnings;

use Moose::Role;

use Data::Riak::Bucket;

# *sigh* Moose
#requires 'bucket_name';
#requires 'riak';

has bucket => (
    is => 'ro',
    isa => 'Data::Riak::Bucket',
    lazy => 1,
    default => sub {
        my $self = shift;
        return Data::Riak::Bucket->new({
            name => $self->bucket_name,
            riak => $self->riak
        });
    }
);

no Moose::Role;

1;

__END__
