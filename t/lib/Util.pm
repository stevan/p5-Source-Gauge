package Util;

use strict;
use warnings;

use DBI;
use Path::Class qw[ dir file tempdir ];

my %DEFAULT_OPTS = (
    database => 'sg',
    host     => 'localhost',
    user     => '',
    password => '',
    sql_path => './db/master.sql'
);

sub get_dbh {
    my %opts = (%DEFAULT_OPTS, @_);
    return DBI->connect(
        (
            'dbi:mysql:database=' . $opts{database} . ';host=' . $opts{host} . ';',
            $opts{user},
            $opts{password},
        ),
        {
            PrintError => 0,
            RaiseError => 1,
        }
    )
}

sub create_database {
    my %opts = (%DEFAULT_OPTS, @_);
    open my $mysql, '|-', _build_mysql_base_cmd( \%opts );
    my $sql = do { open my $fh, '<', $opts{sql_path}; local $/; <$fh> };
    $mysql->print($sql);
    $mysql->close;
    return;
}

sub drop_database {
    my %opts = (%DEFAULT_OPTS, @_);
    open my $mysql, '|-', _build_mysql_base_cmd( \%opts );
    $mysql->print("DROP DATABASE `$_`;") foreach ($opts{database});
    $mysql->close;
}

## --------------------------------------------------------

sub _build_mysql_base_cmd {
    my $opts = $_[0];
    my $cmd = join ' ' => (
        'mysql',
        '--database' => $opts->{database},
        '--host'     => $opts->{host},
        '--user'     => $opts->{user},
        '--password' => $opts->{password},
    );
    return $cmd;
}


1;

__END__
