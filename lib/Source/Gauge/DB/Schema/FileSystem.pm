package Source::Gauge::DB::Schema::FileSystem;
use Moose;

use SQL::Combine::Query::Select::RawSQL;
extends 'SQL::Combine::Table';

has '+name'       => ( default => 'FileSystem' );
has '+table_name' => ( default => 'sg_filesystem' );
has '+driver'     => ( default => 'MySQL' );
has '+columns'    => (
    default => sub {[qw[
        id
        name
        is_file
        is_deleted
        parent_id
    ]]}
);

has 'closure_table_name' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'sg_filesystem_path'
);

sub fully_qualify_closure_table_column_name {
    my ($self, $column_name) = @_;
    return join '.' => ( $self->closure_table_name, $column_name );
}

sub insert_into_closure_table {
    my ($self, %args) = @_;
    return SQL::Combine::Query::Insert->new(
        driver      => $self->driver,
        table_name  => $self->closure_table_name,
        primary_key => 'ancestor', # fuck it, works for now ...
        %args,
    );
}

# Ancestors

sub count_ancestors {
    my ($self, $id) = @_;

    confess 'You must specify an id' unless defined $id;

    return SQL::Combine::Query::Select::RawSQL->new(
        sql          => 'SELECT COUNT(*) from ' . $self->closure_table_name . ' where descendant = ? and ancestor <> ?',
        bind         => [ $id, $id ],
        table_name   => $self->closure_table_name,
        driver       => $self->driver,
        row_inflator => sub {
            my ($row) = @_;
            return +{ count => $row->[0] }
        }
    )
}

sub select_node_and_all_ancestors {
    my ($self, $id) = @_;

    confess 'You must specify an id' unless defined $id;

    my @columns = (
        $self->fully_qualify_column_name('id'),
        $self->fully_qualify_column_name('name'),
        $self->fully_qualify_column_name('is_file'),
        $self->fully_qualify_column_name('parent_id'),
    );

    my @join_clause = (
        $self->fully_qualify_closure_table_column_name('ancestor'),
        $self->fully_qualify_column_name('id'),
    );

    my @where_clause = (
        $self->fully_qualify_closure_table_column_name('descendant'),
        '?'
    );

    return SQL::Combine::Query::Select::RawSQL->new(
        sql => (
            'SELECT ' . (join ', ' => @columns)
          . '  FROM ' . $self->table_name
          . '  JOIN ' . $self->closure_table_name
          . '    ON ' . (join ' = ' => @join_clause)
          . ' WHERE ' . (join ' = ' => @where_clause)
        ),
        bind         => [ $id ],
        table_name   => $self->table_name,
        driver       => $self->driver,
        row_inflator => sub {
            my ($row) = @_;
            return +{
                id        => $row->[0],
                name      => $row->[1],
                is_file   => $row->[2],
                parent_id => $row->[3],
            }
        }
    )
}

# Descendants

sub count_descendants {
    my ($self, $id) = @_;

    confess 'You must specify an id' unless defined $id;

    return SQL::Combine::Query::Select::RawSQL->new(
        sql          => 'SELECT COUNT(*) from ' . $self->closure_table_name . ' where ancestor = ? and descendant <> ?',
        bind         => [ $id, $id ],
        table_name   => $self->closure_table_name,
        driver       => $self->driver,
        row_inflator => sub {
            my ($row) = @_;
            return +{ count => $row->[0] }
        }
    )
}

sub select_node_and_all_descendants {
    my ($self, $id) = @_;

    confess 'You must specify an id' unless defined $id;

    my @columns = (
        $self->fully_qualify_column_name('id'),
        $self->fully_qualify_column_name('name'),
        $self->fully_qualify_column_name('is_file'),
        $self->fully_qualify_column_name('parent_id'),
    );

    my @join_clause = (
        $self->fully_qualify_closure_table_column_name('descendant'),
        $self->fully_qualify_column_name('id'),
    );

    my @where_clause = (
        $self->fully_qualify_closure_table_column_name('ancestor'),
        '?'
    );

    return SQL::Combine::Query::Select::RawSQL->new(
        sql => (
            'SELECT ' . (join ', ' => @columns)
          . '  FROM ' . $self->table_name
          . '  JOIN ' . $self->closure_table_name
          . '    ON ' . (join ' = ' => @join_clause)
          . ' WHERE ' . (join ' = ' => @where_clause)
        ),
        bind         => [ $id ],
        table_name   => $self->table_name,
        driver       => $self->driver,
        row_inflator => sub {
            my ($row) = @_;
            return +{
                id        => $row->[0],
                name      => $row->[1],
                is_file   => $row->[2],
                parent_id => $row->[3],
            }
        }
    )
}

sub insert_descendant {
    my ($self, %opts) = @_;

=pod
    -- adding 8

    my $id = INSERT INTO `sg_filesystem`
        (`name`, `is_file`, `parent_id`)
        VALUES
            ($opts{name}, ($opts{is_file} ? 1 : 0), $opts{parent_id});

    -- adding 8 under 6

    -- SELECT `ancestor` FROM `sg_filesystem_path` WHERE `descendant` = 6;
    -- return [1, 3, 6]

    INSERT INTO `sg_filesystem_path` (`ancestor`, `descendant`) VALUES (1, 8);
    INSERT INTO `sg_filesystem_path` (`ancestor`, `descendant`) VALUES (3, 8);
    INSERT INTO `sg_filesystem_path` (`ancestor`, `descendant`) VALUES (6, 8);

    -- adding 8 itself

    INSERT INTO `sg_filesystem_path` (`ancestor`, `descendant`) VALUES (8, 8);
=cut

}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

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




