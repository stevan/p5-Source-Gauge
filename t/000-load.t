#!/usr/bin/perl

use lib 't/lib';

use strict;
use warnings;

use Test::More;
use Data::Dumper;

use Util;

BEGIN {
    use_ok('Source::Gauge::DB::Schema');
}

my $DBH = Util::get_dbh; # nothing useful for now

my $schema = Source::Gauge::DB::Schema->new( dbh => { rw => $DBH } );
isa_ok($schema, 'Source::Gauge::DB::Schema');

my $time = $schema->table('Dimension::Time');
isa_ok($time, 'Source::Gauge::DB::Schema::Dimension::Time');

my $date = $schema->table('Dimension::Date');
isa_ok($date, 'Source::Gauge::DB::Schema::Dimension::Date');

my $commit = $schema->table('Commit');
isa_ok($commit, 'Source::Gauge::DB::Schema::Commit');

my $author = $schema->table('Commit::Author');
isa_ok($author, 'Source::Gauge::DB::Schema::Commit::Author');

done_testing;
