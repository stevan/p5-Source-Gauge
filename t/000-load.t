#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

use DBI;

BEGIN {
    use_ok('Source::Gauge::DB::Schema');
}

my $DBH = DBI->connect(
    ('dbi:mysql:database=sg;host=localhost', '', ''),
    {
        PrintError => 0,
        RaiseError => 1,
    }
);

my $schema = Source::Gauge::DB::Schema->new( dbh => { rw => $DBH } );
isa_ok($schema, 'Source::Gauge::DB::Schema');

my $time = $schema->table('Dimension::Time');
isa_ok($time, 'Source::Gauge::DB::Schema::Dimension::Time');

my $date = $schema->table('Dimension::Date');
isa_ok($date, 'Source::Gauge::DB::Schema::Dimension::Date');

# $time->generate_csv_data( \*STDOUT );
# $date->generate_csv_data( \*STDOUT, ( start => 2014, end => 2020 ) );

done_testing;
