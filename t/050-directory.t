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
    query    => $fs->select_all_descendants( 3 ),
    inflator => sub {
        my ($results) = @_;
        my %index  = map {
            $_->{children} = [];
            ($_->{id} => $_)
        } @$results;
        my @sorted = sort { $a <=> $b } keys %index;
        my $root   = $sorted[0];
        #warn "Got " . join ", " => @sorted;
        #warn "Got $root";
        foreach my $key ( @sorted ) {
            my $item   = $index{ $key };
            my $parent = $index{ $item->{parent_id} };
            push @{ $parent->{children} } => $item;
        }
        return $index{ $root };
    }
)->execute;

warn Dumper $c;

done_testing;
