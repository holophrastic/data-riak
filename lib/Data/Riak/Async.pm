package Data::Riak::Async;

use Moose;
use Data::Riak::Async::HTTP;
use Data::Riak::Async::Bucket;
use namespace::autoclean;

with 'Data::Riak::Role::Frontend';

sub _build_request_classes {
    return +{
        (map {
            ($_ => 'Data::Riak::Async::Request::' . $_),
        } qw(MapReduce Ping GetBucketProps StoreObject GetObject
             ListBucketKeys RemoveObject LinkWalk Status ListBuckets
             SetBucketProps)),
    }
}

sub _build_bucket_class { 'Data::Riak::Async::Bucket' }

sub _build_mapreduce_class { 'Data::Riak::Async::MapReduce' }

sub send_request {
    my ($self, $request_data) = @_;

    my $request = $self->_create_request($request_data);

    my $cb = $request->cb;
    $self->transport->send(
        $request,
        sub {
            my ($response) = @_;

            my @results = $response->create_results($self, $request);
            return $cb->(undef) unless @results;

            if (@results == 1 && $results[0]->does('Data::Riak::Result::Single')) {
                return $cb->($request->_mangle_retval($results[0]));
            }

            $cb->($request->_mangle_retval(
                Data::Riak::ResultSet->new({ results => \@results }),
            ));
        },
        $request->error_cb,
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;
