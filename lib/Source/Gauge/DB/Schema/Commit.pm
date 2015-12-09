package Source::Gauge::DB::Schema::Commit;
use Moose;

extends 'SQL::Combine::Table';

has '+name'       => ( default => 'Commit' );
has '+table_name' => ( default => 'sg_commit' );
has '+driver'     => ( default => 'MySQL' );
has '+columns'    => (
    default => sub {[qw[
        id

        sha
        message

        author_id
        date_id
        time_id
    ]]}
);

sub select_by_sha {
    my ($self, $sha) = @_;
    my $schema = $self->schema;

    my $Author = $schema->table('Commit::Author');
    my $Date   = $schema->table('Dimension::Date');
    my $Time   = $schema->table('Dimension::Time');

    $self->select(
        columns => [ 'id', 'sha', 'message'],
        where   => [ sha => $sha ],
        join    => [
            {
                source  => $Author->table_name,
                columns => $Author->columns,
                on      => [
                    $self->fully_qualify_column_name('author_id')
                        => { -col => $Author->fully_qualify_primary_key }
                ]
            },
            {
                source  => $Date->table_name,
                columns => [ 'year', 'month', 'day' ],
                on      => [
                    $self->fully_qualify_column_name('date_id')
                        => { -col => $Date->fully_qualify_primary_key }
                ]
            },
            {
                source  => $Time->table_name,
                columns => $Time->columns,
                on      => [
                    $self->fully_qualify_column_name('date_id')
                        => { -col => $Time->fully_qualify_primary_key }
                ]
            }
        ]
    );
}

sub select_associated_files_by_sha {
    my ($self, $sha) = @_;
    my $schema = $self->schema;

    my $File       = $schema->table('Commit::File');
    my $FileSystem = $schema->table('FileSystem');

    $File->select(
        columns => [ 'id', 'added', 'removed' ],
        where   => [ $self->fully_qualify_column_name('sha') => $sha ],
        join    => [
            {
                source  => $self->table_name,
                columns => ['sha'],
                on      => [
                    $File->fully_qualify_column_name('commit_id')
                        => { -col => $self->fully_qualify_column_name('id') },
                ]
            },
            {
                source  => $FileSystem->table_name,
                columns => $FileSystem->columns,
                on      => [
                    $File->fully_qualify_column_name('file_id')
                        => { -col => $FileSystem->fully_qualify_primary_key }
                ]
            }
        ]
    );
}

sub select_associated_files_by_commit_id {
    my ($self, $id) = @_;
    my $schema = $self->schema;

    my $File       = $schema->table('Commit::File');
    my $FileSystem = $schema->table('FileSystem');

    $File->select(
        columns => [ 'id', 'added', 'removed' ],
        where   => [ commit_id => $id ],
        join    => [
            {
                source  => $FileSystem->table_name,
                columns => $FileSystem->columns,
                on      => [
                    $File->fully_qualify_column_name('file_id')
                        => { -col => $FileSystem->fully_qualify_primary_key }
                ]
            }
        ]
    );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
