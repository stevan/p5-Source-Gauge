package Source::Gauge::Script::DB::Importer::GitCommitRange;
use Moose;

use MooseX::Types::Path::Class;
use Path::Class ();

use DateTime;
use DateTime::TimeZone::UTC;
use DateTime::Format::Strptime;

use SQL::Combine::Action::Create::One;
use SQL::Combine::Action::Fetch::One;
use SQL::Combine::Action::Fetch::One::OrCreateOne;

with 'Source::Gauge::Script::DB';

has 'checkout' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    required => 1,
    coerce   => 1,
);

has 'branch' => ( is => 'ro', isa => 'Str', default   => 'master'     );
has 'limit'  => ( is => 'ro', isa => 'Int', predicate => 'has_limit'  );
has 'offset' => ( is => 'ro', isa => 'Int', predicate => 'has_offset' );

sub run {
    my $self = shift;

    my $SG     = $self->schema;
    my $Commit = $SG->table('Commit')          // die 'Cannot find `Commit` table';
    my $Author = $SG->table('Commit::Author')  // die 'Cannot find `Commit::Author` table';
    my $Date   = $SG->table('Dimension::Date') // die 'Cannot find `Dimension::Date` table';
    my $Time   = $SG->table('Dimension::Time') // die 'Cannot find `Dimension::Time` table';

    my $commits = $self->extract_commmit_range;

    $self->log_data( $_ ) foreach reverse @$commits;

    if ($self->dry_run) {
        $self->log('... returning early because of dry_run');
        return;
    }

    $ENV{SQL_COMBINE_DEBUG_SHOW_SQL}++ if $self->verbose;

    foreach my $commit ( reverse @$commits ) {

        my $date = SQL::Combine::Action::Fetch::One->new(
            schema => $SG,
            query  => $Date->select_id_by_datetime( $commit->{date} )
        )->execute;

        my $time = SQL::Combine::Action::Fetch::One->new(
            schema => $SG,
            query  => $Time->select_id_by_datetime( $commit->{date} )
        )->execute;

        my $author = SQL::Combine::Action::Fetch::One::OrCreateOne->new(
            schema => $SG,
            query  => $Author->select(
                columns => [ 'id' ],
                where   => [
                    name  => $commit->{author}->{name},
                    email => $commit->{author}->{email}
                ]
            ),
            or_create => SQL::Combine::Action::Create::One->new(
                schema => $SG,
                query  => $Author->insert(
                    values => [
                        name  => $commit->{author}->{name},
                        email => $commit->{author}->{email}
                    ]
                )
            )
        )->execute;

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

## ----------------------------------------------

sub extract_commmit_range {
    my ($self) = @_;

    my $git_base_cmd = $self->_build_git_base_cmd( $self->checkout );

    my @shas    = $self->_extract_commit_list( $git_base_cmd );
    my @commits = $self->_extract_single_commit( $git_base_cmd, \@shas );

    return \@commits;
}

sub _build_git_base_cmd {
    my ($self, $checkout) = @_;

    my $work_tree = Path::Class::dir( $checkout );

    (-e $work_tree && -d $work_tree)
        || confess 'Could not locate checkout directory (' . $checkout . ')';

    my $git_dir = $work_tree->subdir( '.git' );

    (-e $git_dir && -d $git_dir)
        || confess 'Could not find the .git directory in specified checkout directory (' . $checkout . ')';

    my $git_base_cmd = join ' ' => (
        'git',
        '--git-dir'    => $git_dir->stringify,
        '--work-tree ' => $work_tree->stringify,
    );

    return $git_base_cmd;
}

sub _extract_commit_list {
    my ($self, $git_base_cmd) = @_;

    my $git_rev_list_cmd = join ' ' => (
        $git_base_cmd,
        'rev-list',
        $self->branch,
        ($self->has_limit  ? ( '--max-count' => $self->limit  ) : ()),
        ($self->has_offset ? ( '--skip'      => $self->offset ) : ()),
    );

    # TODO:
    # handle failure of shell command
    # - SL

    my @shas = `$git_rev_list_cmd`;
    chomp foreach @shas;

    return @shas;
}

sub _extract_single_commit {
    my ($self, $git_base_cmd, $shas) = @_;

    my $git_show_cmd = join ' ' => (
        $git_base_cmd,
        'show',
        '--date=iso',
        '--format=format:' . (
            join '%n' => (
                '%H',  # commit hash
                '%an', # author name
                '%ae', # author email
                '%ad', # author date respecting --date
                '%B',  # body
                '%H',  # close
            )
        ),
        '--numstat', # if you remove this, add in -s to supress diff, etc.
        @$shas
    );

    # TODO:
    # handle failure of shell command
    # - SL

    my @all = map { chomp; $_ } `$git_show_cmd`;

    #die join "\n" => @all;

    my $utc_time_zone  = DateTime::TimeZone::UTC->new;
    my $date_formatter = DateTime::Format::Strptime->new(
        # ex: 2015-11-09 00:29:47 +0100
        pattern => '%F %T %z'
    );

    my @commits;
    foreach my $sha ( @$shas ) {
        if ( @all && $all[0] eq $sha ) {
            shift @all; # discard the commit line
            my $author_name  = shift @all;
            my $author_email = shift @all;
            # parse the date and ...
            my $author_date  = $date_formatter->parse_datetime( shift @all );
            # ... normalize to UTC
            $author_date->set_time_zone( $utc_time_zone );
            # now collect the message
            my @body;
            push @body => shift @all
                while @all && $all[0] ne $sha;
            shift @all; # discard the closing commit line

            # collect all the file details ...
            my @files;
            while ( @all && $all[0] !~ /^\s*$/ ) {
                my $line = shift @all;
                my ($added, $removed, $path) = split /\s+/ => $line;
                push @files => {
                    path    => $path,
                    added   => $added,
                    removed => $removed
                };
            }

            shift @all; # discard the empty newline

            # build our commit object ...
            push @commits => {
                sha     => $sha,
                author  => { name => $author_name, email => $author_email },
                date    => $author_date,
                message => \@body,
                files   => \@files,
            };
        }
        else {
            confess 'This should never happen, '
                  . 'looking for (' . $sha . ') '
                  . 'but found (' . $all[0] . ') '
                  . "in:\n" . (join "\n" => @all);
        }
    }

    return @commits;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
