package Source::Gauge::DB::Schema::Commit::File;
use Moose;

extends 'SQL::Combine::Table';

has '+name'       => ( default => 'Commit::File' );
has '+table_name' => ( default => 'sg_commit_file' );
has '+driver'     => ( default => 'MySQL' );
has '+columns'    => (
    default => sub {[qw[
        id
        commit_id
        file_id
        added
        removed
    ]]}
);

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
