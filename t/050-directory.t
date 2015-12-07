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
    query    => $fs->select_descendants( 2 )
)->execute;

warn Dumper $c;

done_testing;

__DATA__

FROM: http://stackoverflow.com/questions/6802539/hierarchical-tree-database-for-directories-in-filesystem

        (ROOT)
      /        \
    Dir2        Dir3
    /    \           \
  Dir4   Dir5        Dir6
  /
Dir7

INSERT INTO sg_filesystem (id, dirname) VALUES (1, 'ROOT');
INSERT INTO sg_filesystem (id, dirname) VALUES (2, 'Dir2');
INSERT INTO sg_filesystem (id, dirname) VALUES (3, 'Dir3');
INSERT INTO sg_filesystem (id, dirname) VALUES (4, 'Dir4');
INSERT INTO sg_filesystem (id, dirname) VALUES (5, 'Dir5');
INSERT INTO sg_filesystem (id, dirname) VALUES (6, 'Dir6');
INSERT INTO sg_filesystem (id, dirname) VALUES (7, 'Dir7');

INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (1, 1);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (1, 2);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (1, 3);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (1, 4);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (1, 5);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (1, 6);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (1, 7);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (2, 2);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (2, 4);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (2, 5);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (2, 7);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (3, 3);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (3, 6);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (4, 4);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (4, 7);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (5, 5);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (6, 6);
INSERT INTO sg_filesystem_tree (ancestor, descendant) VALUES (7, 7);

# (ROOT) and subdirectories
SELECT f.id, f.dirname
  FROM sg_filesystem f
  JOIN sg_filesystem_tree t
    ON t.descendant = f.id
 WHERE t.ancestor = 1;

+----+---------+
| id | dirname |
+----+---------+
|  1 | ROOT    |
|  2 | Dir2    |
|  3 | Dir3    |
|  4 | Dir4    |
|  5 | Dir5    |
|  6 | Dir6    |
|  7 | Dir7    |
+----+---------+


# Dir3 and subdirectories
SELECT f.id, f.dirname
  FROM sg_filesystem f
  JOIN sg_filesystem_tree t
    ON t.descendant = f.id
 WHERE t.ancestor = 3;

+----+---------+
| id | dirname |
+----+---------+
|  3 | Dir3    |
|  6 | Dir6    |
+----+---------+

# Dir5 and parent directories
SELECT f.id, f.dirname
  FROM sg_filesystem f
  JOIN sg_filesystem_tree t
    ON t.ancestor = f.id
 WHERE t.descendant = 5;

+----+---------+
| id | dirname |
+----+---------+
|  1 | ROOT    |
|  2 | Dir2    |
|  5 | Dir5    |
+----+---------+

# Dir7 and parent directories
SELECT f.id, f.dirname
  FROM sg_filesystem f
  JOIN sg_filesystem_tree t
    ON t.ancestor = f.id
 WHERE t.descendant = 7;

+----+---------+
| id | dirname |
+----+---------+
|  1 | ROOT    |
|  2 | Dir2    |
|  4 | Dir4    |
|  7 | Dir7    |
+----+---------+

# Dir7 and parent directories as a path
SELECT GROUP_CONCAT(f.dirname, '/') AS path
  FROM sg_filesystem f
  JOIN sg_filesystem_tree t
    ON t.ancestor = f.id
 WHERE t.descendant = 7;

+---------------------+
| path                |
+---------------------+
| ROOT/Dir2/Dir4/Dir7 |
+---------------------+

SELECT f.id, f.dirname
  FROM sg_filesystem f
  JOIN sg_filesystem_tree t
    ON t.ancestor = f.id
 WHERE t.descendant = (
SELECT id
  FROM sg_filesystem
 WHERE dirname LIKE '%7%'
);

+----+---------+
| id | dirname |
+----+---------+
|  1 | ROOT    |
|  2 | Dir2    |
|  4 | Dir4    |
|  7 | Dir7    |
+----+---------+

