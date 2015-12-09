#!/usr/bin/perl

use lib 't/lib';

use strict;
use warnings;

use Test::More;
use Data::Dumper;

use SQL::Combine::Action::Fetch::One;
use SQL::Combine::Action::Fetch::Many;

use Util;

BEGIN {
    use_ok('Source::Gauge::DB::Schema');
}

my $DBH = Util::get_dbh;

my $schema = Source::Gauge::DB::Schema->new( dbh => { rw => $DBH } );
isa_ok($schema, 'Source::Gauge::DB::Schema');

my $commit = $schema->table('Commit');
isa_ok($commit, 'Source::Gauge::DB::Schema::Commit');

{
    my $c = SQL::Combine::Action::Fetch::One->new(
        schema   => $schema,
        query    => $commit->select_by_sha('1947c5e3cf7003cdbf26f50df109f5dab4dbff10'),
        inflator => sub {
            my $result = $_[0];
            return +{
                author => (delete $result->{sg_commit_author}),
                date   => (join ' ' => (
                    (join '-', @{ delete $result->{sg_date_dimension} }{qw[ year month day ]}),
                    (join ':', @{ delete $result->{sg_time_dimension} }{qw[ hour minute second ]})
                )),
                (%$result)
            }
        }
    )->relates_to(
        files => SQL::Combine::Action::Fetch::Many->new(
            schema   => $schema,
            query    => sub {
                my ($result) = @_;
                $commit->select_associated_files_by_commit_id( $result->{id} )
            },
            inflator => sub {
                my ($results) = @_;
                return [
                    map +{
                        file => (delete $_->{sg_filesystem}),
                        %$_
                    }, @$results
                ]
            }
        )
    )->execute;

    warn Dumper $c;
}


done_testing;
