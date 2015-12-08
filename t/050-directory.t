#!/usr/bin/perl

use lib 't/lib';

use strict;
use warnings;

use Test::More;
use Data::Dumper;

use SQL::Combine::Action::Fetch::Many;

use Util;

BEGIN {
    use_ok('Source::Gauge::DB::Schema');
}

my $DBH = Util::get_dbh;

my $schema = Source::Gauge::DB::Schema->new( dbh => { rw => $DBH } );
isa_ok($schema, 'Source::Gauge::DB::Schema');

my $fs = $schema->table('FileSystem');
isa_ok($fs, 'Source::Gauge::DB::Schema::FileSystem');

my $c = SQL::Combine::Action::Fetch::Many->new(
    schema   => $schema,
    query    => $fs->select_descendants( 3 )
)->execute;

warn Dumper $c;

done_testing;
