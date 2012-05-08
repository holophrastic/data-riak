#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dump;
use Digest::MD5 qw/md5_hex/;

use Test::Exception;
use Test::More;
use Test::Data::Riak;

use Data::Riak::HTTP;
use Data::Riak::HTTP::Bucket;

skip_unless_riak;

my $riak = Data::Riak::HTTP->new;
#my $bucket_name = md5_hex(scalar localtime);

#my $bucket = Data::Riak::HTTP::Bucket->new({
#    name => $bucket_name,
#    riak => $riak
#});

#$bucket->add('foo', 'dog');
#$bucket->add('bar', 'cat');
#$bucket->add('baz', 'dogs and cats living together');
#$bucket->add('qux', 'gerbils');

#my $mr = Data::Riak::HTTP::MapReduce->new;

#my $results = $mr->mapreduce({ });
#ddx($results);

# Implement the example from the Riak docs.

my $bucket_name = md5_hex(scalar localtime);

my $bucket = Data::Riak::HTTP::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

my $text1 = "
Alice was beginning to get very tired of sitting by her sister on the
bank, and of having nothing to do: once or twice she had peeped into the
book her sister was reading, but it had no pictures or conversations in
it, 'and what is the use of a book,' thought Alice 'without pictures or
conversation?'
";

my $text2 = "
So she was considering in her own mind (as well as she could, for the
hot day made her feel very sleepy and stupid), whether the pleasure
of making a daisy-chain would be worth the trouble of getting up and
picking the daisies, when suddenly a White Rabbit with pink eyes ran
close by her.
";

my $text3 = "
The rabbit-hole went straight on like a tunnel for some way, and then
dipped suddenly down, so suddenly that Alice had not a moment to think
about stopping herself before she found herself falling down a very deep
well.
";

$bucket->add('p1', $text1);
$bucket->add('p2', $text2);
$bucket->add('p5', $text3);

my $mr = Data::Riak::MapReduce->new({
    riak => $riak,
    inputs => [ [ $bucket_name, "p1" ], [ $bucket_name, "p2" ], [ $bucket_name, "p5" ] ],
    map => {
        language => 'javascript',
        source => 'function(v) { var m = v.values[0].data.toLowerCase().match(/\w*/g); var r = []; for(var i in m) { if(m[i] != "") { var o = {}; o[m[i]] = 1; r.push(o); } } return r; } '
    },
    reduce => {
        language => 'javascript',
        source => 'function(v) { var r = {}; for(var i in v) { for(var w in v[i]) { if(w in r) r[w] += v[i][w];       else r[w] = v[i][w]; } } return [r]; }'
    }
});
my $results = $mr->mapreduce;
#ddx($results);
#ddx($mr);
print $results->http_response->content;










