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

my $fs = $schema->table('FileSystem');
isa_ok($fs, 'Source::Gauge::DB::Schema::FileSystem');

my $bin = SQL::Combine::Action::Fetch::One->new(
    schema => $schema,
    query  => $fs->select(
        columns => ['id'],
        where   => [ name => 'bin' ]
    ),
    inflator => sub { $_[0]->{tree} }
)->relates_to(
    tree => SQL::Combine::Action::Fetch::Many->new(
        schema   => $schema,
        query    => sub {
            my ($result) = @_;
            $fs->select_node_and_all_descendants( $result->{id} )
        },
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
    )
);

warn Dumper $bin->execute;

=pod
{
    my $c = SQL::Combine::Action::Fetch::One->new(
        schema => $schema,
        query  => $fs->count_descendants( 3 ),
    )->execute;

    warn Dumper $c;
}

{
    my $c = SQL::Combine::Action::Fetch::Many->new(
        schema   => $schema,
        query    => $fs->select_node_and_all_ancestors( 8 ),
        inflator => sub {
            my ($results) = @_;
            my %index  = map {
                $_->{children} = [];
                ($_->{id} => $_)
            } @$results;
            my ($root) = grep not( defined( $_->{parent_id} ) ), @$results;
            #warn "Got " . join ", " => @sorted;
            #warn "Got $root";
            foreach my $key ( keys %index ) {
                my $item   = $index{ $key };
                if ( $item->{parent_id} ) {
                    my $parent = $index{ $item->{parent_id} };
                    push @{ $parent->{children} } => $item;
                }
            }
            return $index{ $root->{id} };
        }
    )->execute;

    warn Dumper $c;
}

{
    my $c = SQL::Combine::Action::Fetch::Many->new(
        schema => $schema,
        query  => $fs->count_ancestors( 8 ),
    )->execute;

    warn Dumper $c;
}
=cut

done_testing;
