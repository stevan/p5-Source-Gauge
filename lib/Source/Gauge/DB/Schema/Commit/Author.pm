package Source::Gauge::DB::Schema::Commit::Author;
use Moose;

extends 'SQL::Combine::Table';

has '+name'       => ( default => 'Commit::Author' );
has '+table_name' => ( default => 'sg_commit_author' );
has '+driver'     => ( default => 'MySQL' );
has '+columns'    => (
    default => sub {[qw[
        id
        name
        email
    ]]}
);

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
