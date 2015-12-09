package Source::Gauge::Script::DB::Importer::GitCommitRange;
use Moose;

use MooseX::Types::Path::Class;
use Path::Class ();

use DateTime;
use DateTime::TimeZone::UTC;
use DateTime::Format::Strptime;

use SQL::Combine::Action::Create::One;
use SQL::Combine::Action::Create::Many;

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

    my $SG         = $self->schema;
    my $Commit     = $SG->table('Commit')          // die 'Cannot find `Commit` table';
    my $Author     = $SG->table('Commit::Author')  // die 'Cannot find `Commit::Author` table';
    my $File       = $SG->table('Commit::File')    // die 'Cannot find `Commit::File` table';
    my $Date       = $SG->table('Dimension::Date') // die 'Cannot find `Dimension::Date` table';
    my $Time       = $SG->table('Dimension::Time') // die 'Cannot find `Dimension::Time` table';
    my $FileSystem = $SG->table('FileSystem')      // die 'Cannot find `FileSystem` table';

    my $commits = $self->extract_commmit_range;

    $self->log_data( [ map +{ %$_, date => ''.$_->{date} }, reverse @$commits ] );

    if ($self->dry_run) {
        $self->log('... returning early because of dry_run');
        return;
    }

    $ENV{SQL_COMBINE_DEBUG_SHOW_SQL}++ if $self->verbose;

    # transaction??

    foreach my $c ( reverse @$commits ) {

        # TODO:
        # Check to see if we got something back
        # from these two queries ...
        # - SL

        my $date = SQL::Combine::Action::Fetch::One->new(
            schema => $SG,
            query  => $Date->select_id_by_datetime( $c->{date} )
        )->execute;

        my $time = SQL::Combine::Action::Fetch::One->new(
            schema => $SG,
            query  => $Time->select_id_by_datetime( $c->{date} )
        )->execute;

        my $author = SQL::Combine::Action::Fetch::One::OrCreateOne->new(
            schema => $SG,
            query  => $Author->select(
                columns => [ 'id' ],
                where   => [
                    name  => $c->{author}->{name},
                    email => $c->{author}->{email}
                ]
            ),
            or_create => SQL::Combine::Action::Create::One->new(
                schema => $SG,
                query  => $Author->insert(
                    values => [
                        name  => $c->{author}->{name},
                        email => $c->{author}->{email}
                    ]
                )
            )
        )->execute;

        my $commit = SQL::Combine::Action::Create::One->new(
            schema => $SG,
            query  => $Commit->upsert(
                values => [
                    sha       => $c->{sha},
                    message   => (join "\n" => @{$c->{message}}),
                    author_id => $author->{id},
                    date_id   => $date->{id},
                    time_id   => $time->{id},
                ]
            )
        )->execute;

        if ( my $files = $c->{files} ) {
            foreach my $file ( @$files ) {
                my $file_obj  = Path::Class::File->new( delete $file->{path} );


                if ( my $action = delete $file->{action} ) {
                    # do something about the action
                }

                my $file_data = SQL::Combine::Action::Fetch::One->new(
                    schema => $SG,
                    query  => $FileSystem->select(
                        columns => ['id'],
                        where   => [ 'name' => $file_obj->basename ]
                    )
                )->execute;

                # TODO:
                # 1) Check to see if we got something back
                # 2) Check to see if the path we got back
                #    matches the one we got
                # - SL

                $file->{file_id} = $file_data->{id};
            }

            my $commit_files = SQL::Combine::Action::Create::Many->new(
                schema  => $SG,
                queries => [
                    map $File->insert(
                        values => [
                            commit_id => $commit->{id},
                            %$_
                        ]
                    ), grep defined($_->{file_id}), @$files
                ]
            )->execute;
        }
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
        '--numstat',
        '--summary',
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

    #die join "\n" => @all;

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
            my %files;
            while ( @all && $all[0] =~ /^\d+/ ) {
                my $line = shift @all;
                my ($added, $removed, $path) = split /\s+/ => $line;
                $files{ $path } = {
                    path    => $path,
                    added   => $added,
                    removed => $removed
                };
            }

            while ( @all && $all[0] =~ /^\s[create|delete]/ ) {
                my $line = shift @all;
                #warn $line;
                my ($action, $path) = ($line =~ /^\s(.*) mode \d+ (.*)/);
                #warn join ", " => $action, $path;
                $files{ $path }->{action} = $action;
            }

            shift @all while @all && $all[0] =~ /^\s*$/; # discard the empty newlines

            # build our commit object ...
            push @commits => {
                sha     => $sha,
                author  => { name => $author_name, email => $author_email },
                date    => $author_date,
                message => \@body,
                files   => [ values %files ],
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
