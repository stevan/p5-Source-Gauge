package Source::Gauge::Script::DB::Importer::RootDirectory;
use Moose;

=pod

NOTE:

This class is probably a bad idea, we actually need to
import our filesystem data from the git commits.

=cut

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

has 'start_id' => ( is => 'ro', isa => 'Int', default => 0 );

sub run {
    my $self = shift;

    my $SG         = $self->schema;
    my $FileSystem = $SG->table('FileSystem') // die 'Cannot find `FileSystem` table';

    my ($fs_table, $fs_table_path) = $self->extract_filesystem;

    $self->log('%s => %s' => @$_) foreach @$fs_table;
    $self->log('%s => %s => %s' => @$_) foreach @$fs_table_path;

    if ($self->dry_run) {
        $self->log('... returning early because of dry_run');
        return;
    }

    $ENV{SQL_COMBINE_DEBUG_SHOW_SQL}++ if $self->verbose;

    SQL::Combine::Action::Create::Many->new(
        schema  => $SG,
        queries => [
            (map $FileSystem->insert(
                values => [
                    id         => $_->[0],
                    name       => $_->[1],
                    is_file    => $_->[2],
                    is_deleted => 0, # clearly these still exist ...
                    parent_id  => $_->[3],
                ]
            ), @$fs_table),
            (map $FileSystem->insert_into_closure_table(
                values => [
                    ancestor   => $_->[0],
                    descendant => $_->[1],
                    length     => $_->[2],
                ]
            ), @$fs_table_path)
        ]
    )->execute;

    return;
}

sub extract_filesystem {
    my ($self) = @_;

    my $current_id = $self->start_id;
    my @stack;

    my @fs_table;
    my @fs_table_path;

    my %temp_fs_table_path;

    my $traverse = sub {
        my ($node) = @_;

        push @fs_table => [ ++$current_id, $node->basename, (-f $node ? 1 : 0), $stack[-1] ];
        push @stack    => $fs_table[-1]->[0];

        foreach my $item ( @stack ) {
            $temp_fs_table_path{ $item } //= [];
            push @{$temp_fs_table_path{ $item }} => [ $current_id, $#stack ];
        }

        if ( -d $node ) {
            # TODO:
            # We need to actually parse the .gitignore file
            # and then mask off the directory using that
            # the alternate would be having git somehoe tell
            # us what we should care about.
            # - SL
            foreach my $child ( $node->children ) {
                # for now we can just do this ugliness
                next if -d $child && $child->basename =~ /^\./;
                next if $child->basename eq '.DS_Store';

                # and recurse ...
                __SUB__->( $child );
            }
        }

        pop @stack;
        return;
    };

    $traverse->( $self->dir );

    foreach my $i ( sort { $a <=> $b } keys %temp_fs_table_path ) {
        foreach my $j ( @{ $temp_fs_table_path{ $i } } ) {
            push @fs_table_path => [ $i, @$j ];
        }
    }

    return \@fs_table, \@fs_table_path;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
