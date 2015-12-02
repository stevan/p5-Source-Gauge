#!/usr/bin/perl

use lib 't/lib';

use strict;
use warnings;

use Test::More;
use Data::Dumper;

use SQL::Combine::Action::Fetch::One;

use Util;

BEGIN {
    use_ok('Source::Gauge::DB::Schema');
}

my $DBH = Util::get_dbh;

my $schema = Source::Gauge::DB::Schema->new( dbh => { rw => $DBH } );
isa_ok($schema, 'Source::Gauge::DB::Schema');

my $commit = $schema->table('Commit');
isa_ok($commit, 'Source::Gauge::DB::Schema::Commit');

my $c = SQL::Combine::Action::Fetch::One->new(
    schema   => $schema,
    query    => $commit->select_by_sha('b0e1b3a80b0bddb7cea519f4cc2ba4c0e477c98f'),
    inflator => sub {
        my $result = $_[0];
        return +{
            sha    => $result->{sha},
            author => $result->{sg_commit_author},
            date   => join ' ' => (
                (join '-', @{ $result->{sg_date_dimension} }{qw[ year month day ]}),
                (join ':', @{ $result->{sg_time_dimension} }{qw[ hour minute second ]})
            )
        }
    }
)->execute;

warn Dumper $c;

done_testing;
