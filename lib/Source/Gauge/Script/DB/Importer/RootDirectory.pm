package Source::Gauge::Script::DB::Importer::RootDirectory;
use Moose;

use feature 'current_sub';

use MooseX::Types::Path::Class;
use Path::Class ();

use List::AllUtils ();

use SQL::Combine::Action::Create::Many;

with 'Source::Gauge::Script::DB';

has 'dir' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    required => 1,
    coerce   => 1,
);

has 'start_id' => ( is => 'ro', isa => 'Int', default => 1 );

sub run {
    my $self = shift;

    my $SG         = $self->schema;
    my $FileSystem = $SG->table('FileSystem') // die 'Cannot find `FileSystem` table';

    my ($fs_table, $fs_table_path) = $self->extract_filesystem;

    $self->log('%s => %s' => @$_) foreach @$fs_table;
    $self->log('%s => %s' => @$_) foreach @$fs_table_path;

    $ENV{SQL_COMBINE_DEBUG_SHOW_SQL}++ if $self->verbose;

    SQL::Combine::Action::Create::Many->new(
        schema  => $SG,
        queries => [
            (map $FileSystem->insert(
                values => [
                    id        => $_->[0],
                    name      => $_->[1],
                    is_file   => $_->[2],
                    parent_id => $_->[3],
                ]
            ), @$fs_table),
            (map $FileSystem->insert_into_closure_table(
                values => [
                    ancestor   => $_->[0],
                    descendant => $_->[1],
                ]
            ), @$fs_table_path)
        ]
    )->execute;
}

sub extract_filesystem {
    my ($self) = @_;

    my $current_id = $self->start_id;
    my @stack;

    my @fs_table;
    my @fs_table_path;

    my @temp_fs_table_path;

    my $traverse = sub {
        my ($node) = @_;

        foreach my $item ( @stack ) {
            push @{
                $temp_fs_table_path[ $item - 1 ] //= []
            } => $current_id;
        }

        push @fs_table => [ $current_id++, $node->basename, (-f $node ? 1 : 0), $stack[-1] ];
        push @stack    => $fs_table[-1]->[0];

        if ( -d $node ) {
            foreach my $child ( $node->children( no_hidden => 1 ) ) {
                __SUB__->( $child );
            }
        }

        pop @stack;
        return;
    };

    $traverse->( $self->dir );

    foreach my $i ( 0 .. $#temp_fs_table_path ) {
        foreach my $j ( @{ $temp_fs_table_path[ $i ] } ) {
            push @fs_table_path => [ ($i + 1), $j ]
        }
    }

    return \@fs_table, \@fs_table_path;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
