package Source::Gauge::Script::DB;
use Moose::Role;

use DBI;
use Source::Gauge::DB::Schema;

with 'Source::Gauge::Script';

has 'dsn'      => ( is => 'ro', isa => 'Str', required => 1 );
has 'user'     => ( is => 'ro', isa => 'Str', default => '' );
has 'password' => ( is => 'ro', isa => 'Str', default => '' );

has 'schema' => (
    init_arg => undef,
    is       => 'ro',
    isa      => 'Source::Gauge::DB::Schema',
    lazy     => 1,
    builder  => '_build_schema'
);

sub _build_schema {
    my $self = shift;

    my $dbh = DBI->connect(
        $self->dsn, $self->user, $self->password,
        {
            PrintError => 0,
            RaiseError => 1,
        }
    );

    return Source::Gauge::DB::Schema->new( dbh => { rw => $dbh } );
}

no Moose::Role; 1;

__END__
