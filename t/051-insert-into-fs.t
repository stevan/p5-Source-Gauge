#!/usr/bin/perl

use lib 't/lib';

use strict;
use warnings;

use Test::More;
use Data::Dumper;

use SQL::Combine::Action::Fetch::One;
use SQL::Combine::Action::Fetch::Many;
use SQL::Combine::Action::Create::One;

use Util;

BEGIN {
    use_ok('Source::Gauge::DB::Schema');
}

my $FILENAME  = '051-test';
my $PARENT_ID = 1;

my $DBH = Util::get_dbh;

my $schema = Source::Gauge::DB::Schema->new( dbh => { rw => $DBH } );
isa_ok($schema, 'Source::Gauge::DB::Schema');

my $fs = $schema->table('FileSystem');
isa_ok($fs, 'Source::Gauge::DB::Schema::FileSystem');

my $fetch_test = SQL::Combine::Action::Fetch::One->new(
    schema => $schema,
    query  => $fs->select(
        columns => ['id'],
        where   => [ name => $FILENAME ]
    ),
)->relates_to(
    tree => SQL::Combine::Action::Fetch::Many->new(
        schema   => $schema,
        query    => sub {
            my ($result) = @_;
            $fs->select_node_and_all_descendants( $result->{id} )
        }
    )
);

{
    my $results = $fetch_test->execute;
    ok(not(defined($results)), '... got nothing back');
}

my $insert_test = SQL::Combine::Action::Create::One->new(
    schema => $schema,
    query  => $fs->insert_node( name => $FILENAME, parent_id => $PARENT_ID )
)->relates_to(
    path_insert => SQL::Combine::Action::Create::One->new(
        schema => $schema,
        query  => sub {
            my ($node) = @_;
            $fs->insert_node_into_tree(
                $node->{id},
                $PARENT_ID
            )
        }
    )
);

{
    my $results = $insert_test->execute;
    ok($results->{id}, '... got the ID we expected');
}

{
    my $results = $fetch_test->execute;
    use Data::Dumper;
    warn Dumper $results;
}


done_testing;
