package Source::Gauge::DB::Schema::Dimension::Time;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use DateTime;

use parent 'SQL::Combine::Table';

sub new {
    my ($class, %args) = @_;

    $args{name}       //= 'Dimension::Time';
    $args{table_name} //= 'sg_time_dimension';
    $args{driver}     //= 'MySQL';
    $args{columns}    //= [qw[
        id

        second
        minute
        hour
    ]];

    return $class->SUPER::new( %args );
}

sub select_id_by_datetime {
    my ($self, $datetime, @additional_columns) = @_;

    confess 'You must specify a datetime object'
        unless blessed $datetime
            && $datetime->isa('DateTime');

    return $self->select(
        columns => [ $self->primary_key, @additional_columns ],
        where   => [
            second => $datetime->second,
            minute => $datetime->minute,
            hour   => $datetime->hour,
        ]
    );
}

1;

__END__
