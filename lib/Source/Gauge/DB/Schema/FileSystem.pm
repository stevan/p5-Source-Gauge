package Source::Gauge::DB::Schema::FileSystem;
use Moose;

use SQL::Combine::Query::Select::RawSQL;
use SQL::Combine::Query::Insert::RawSQL;

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

sub insert_node {
    my ($self, %node) = @_;
    $self->insert(
        values => [
            name       => $node{name}       // confess 'You must specify a `name` parameter',
            is_file    => $node{is_file}    // 0,
            is_deleted => $node{is_deleted} // 0,
            parent_id  => $node{parent_id}  // confess 'You must specify a `parent_id` parameter',
        ]
    );
}

sub insert_node_into_tree {
    my ($self, $id, $parent_id) = @_;

    confess 'You must specify an id'       unless defined $id;
    confess 'You must specify a parent_id' unless defined $parent_id;

    my $c_table = $self->closure_table_name;

    return SQL::Combine::Query::Insert::RawSQL->new(
        sql => (
            'INSERT INTO ' . $c_table . ' (ancestor, descendant, length) '
          . 'SELECT ancestor, ?, length + 1'
          . '  FROM ' . $c_table
          . ' WHERE descendant = ?'
          . ' UNION ALL (SELECT ?, ?, length + 1 '
                       . '  FROM ' . $c_table
                       . ' WHERE descendant = ? LIMIT 1)'
        ),
        # NOTE:
        # above here, in the second query, we LIMIT 1 because
        # we need to the length to +1 against, otherwise we
        # could have just done (SELECT ?, ?) where the ? would
        # become the id of the newly inserted row.
        bind => [
            # in the first embedded SELECT, we need ...
            $id,        # the new id to populate the descendant column
            $parent_id, # the parent id to find all the ancestors
            # then in the second UNION-ed SELECT we need ...
            $id,        # the new id to populate the ancestor column
            $id,        # the new id to populate the descendant column
            $parent_id, # the parent id to find all the ancestors
        ],
        table_name   => $c_table,
        driver       => $self->driver,
    );
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
