package Source::Gauge::DB::Schema::FileSystem;
use Moose;

extends 'SQL::Combine::Table';

has '+name'       => ( default => 'FileSystem' );
has '+table_name' => ( default => 'sg_filesystem' );
has '+driver'     => ( default => 'MySQL' );
has '+columns'    => (
    default => sub {[qw[
        id
        name
    ]]}
);

has 'closure_table_name' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'sg_filesystem_path'
);

sub count_descendants {
    my ($self, $id) = @_;
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

sub fully_qualify_closure_table_column_name {
    my ($self, $column_name) = @_;
    return join '.' => ( $self->closure_table_name, $column_name );
}

sub select_descendants {
    my ($self, $id) = @_;

    my @columns = (
        $self->fully_qualify_column_name('id'),
        $self->fully_qualify_column_name('name'),
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
                id   => $row->[0],
                name => $row->[1]
            }
        }
    )
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
