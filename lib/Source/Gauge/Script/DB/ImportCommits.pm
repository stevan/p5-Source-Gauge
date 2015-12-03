package Source::Gauge::Script::DB::ImportCommits;
use Moose;

use MooseX::Types::Path::Class;

use SQL::Combine::Action::Create::One;
use SQL::Combine::Action::Fetch::One;

with 'Source::Gauge::Script::DB';

has 'checkout' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    required => 1,
    coerce   => 1,
);

has 'limit'  => ( is => 'ro', isa => 'Int' );
has 'offset' => ( is => 'ro', isa => 'Int' );

sub run {
    my $self = shift;

    my $SG     = $self->schema;
    my $Commit = $SG->table('Commit')          // die 'Cannot find `Commit` table';
    my $Author = $SG->table('Commit::Author')  // die 'Cannot find `Commit::Author` table';
    my $Date   = $SG->table('Dimension::Date') // die 'Cannot find `Dimension::Date` table';
    my $Time   = $SG->table('Dimension::Time') // die 'Cannot find `Dimension::Time` table';

    my $commits = $Commit->extract_commmit_range(
        checkout => $self->checkout,
        limit    => $self->limit,
        offset   => $self->offset,
    );

    $ENV{SQL_COMBINE_DEBUG_SHOW_SQL}++ if $self->verbose;

    foreach my $commit ( @$commits ) {

        my $date = SQL::Combine::Action::Fetch::One->new(
            schema => $SG,
            query  => $Date->select_id_by_datetime( $commit->{date} )
        )->execute;

        my $time = SQL::Combine::Action::Fetch::One->new(
            schema => $SG,
            query  => $Time->select_id_by_datetime( $commit->{date} )
        )->execute;

        # TODO:
        # Need a Find Or Create Action
        # - SL
        my $author = SQL::Combine::Action::Fetch::One->new(
            schema => $SG,
            query  => $Author->select(
                columns => [ 'id' ],
                where   => [
                    name  => $commit->{author}->{name},
                    email => $commit->{author}->{email}
                ]
            )
        )->execute;

        unless ( $author ) {
            $author = SQL::Combine::Action::Create::One->new(
                schema => $SG,
                query  => $Author->insert(
                    values => [
                        name  => $commit->{author}->{name},
                        email => $commit->{author}->{email}
                    ]
                )
            )->execute;
        }

        my $commit = SQL::Combine::Action::Create::One->new(
            schema => $SG,
            query  => $Commit->upsert(
                values => [
                    sha       => $commit->{sha},
                    message   => (join "\n" => @{$commit->{message}}),
                    author_id => $author->{id},
                    date_id   => $date->{id},
                    time_id   => $time->{id},
                ]
            )
        )->execute;
    }

    return;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
