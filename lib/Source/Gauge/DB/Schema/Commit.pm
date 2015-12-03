package Source::Gauge::DB::Schema::Commit;
use Moose;

use DateTime;
use DateTime::Format::Strptime;
use DateTime::TimeZone::UTC;

use Path::Class;

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

## ----------------------------------------------

sub select_by_sha {
    my ($self, $sha) = @_;
    $self->select(
        columns => ['sha'],
        join    => [
            {
                source  => 'sg_commit_author',
                columns => [ 'name', 'email' ],
                on      => [ 'sg_commit.author_id' => { -col => 'sg_commit_author.id' } ]
            },
            {
                source  => 'sg_date_dimension',
                columns => [ 'year', 'month', 'day' ],
                on      => [ 'sg_commit.date_id' => { -col => 'sg_date_dimension.id' } ]
            },
            {
                source  => 'sg_time_dimension',
                columns => [ 'hour', 'minute', 'second' ],
                on      => [ 'sg_commit.time_id' => { -col => 'sg_time_dimension.id' } ]
            }
        ]
    );
}

## ----------------------------------------------

sub extract_commmit_range {
    my ($self, %opts) = @_;

    (exists $opts{'checkout'})
        || confess 'You must specify a `checkout` option';

    my $git_base_cmd = $self->_build_git_base_cmd( $opts{'checkout'} );

    $opts{'branch'} //= 'master';

    my @shas    = $self->_extract_commit_list( $git_base_cmd, \%opts );
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
    my ($self, $git_base_cmd, $opts) = @_;

    my $git_rev_list_cmd = join ' ' => (
        $git_base_cmd,
        'rev-list',
        $opts->{branch},
        (defined $opts->{limit}  ? ( '--max-count' => $opts->{limit}  ) : ()),
        (defined $opts->{offset} ? ( '--skip'      => $opts->{offset} ) : ()),
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
