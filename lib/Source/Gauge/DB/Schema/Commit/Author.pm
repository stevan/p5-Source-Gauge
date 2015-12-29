package Source::Gauge::DB::Schema::Commit::Author;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use parent 'SQL::Combine::Table';

sub new {
    my ($class, %args) = @_;

    $args{name}       //= 'Commit::Author';
    $args{table_name} //= 'sg_commit_author';
    $args{driver}     //= 'MySQL';
    $args{columns}    //= [qw[
        id

        name
        email
    ]];

    return $class->SUPER::new( %args );
}

1;

__END__
