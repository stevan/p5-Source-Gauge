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
