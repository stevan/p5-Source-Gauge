package Source::Gauge::DB::Schema::Commit::File;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use parent 'SQL::Combine::Table';

sub new {
    my ($class, %args) = @_;

    $args{name}       //= 'Commit::File';
    $args{table_name} //= 'sg_commit_file';
    $args{driver}     //= 'MySQL';
    $args{columns}    //= [qw[
        id

        commit_id
        file_id
        added
        removed
    ]];

    return $class->SUPER::new( %args );
}

1;

__END__
