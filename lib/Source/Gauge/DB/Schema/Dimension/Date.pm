package Source::Gauge::DB::Schema::Dimension::Date;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use DateTime;

use parent 'SQL::Combine::Table';

sub new {
    my ($class, %args) = @_;

    $args{name}       //= 'Dimension::Date';
    $args{table_name} //= 'sg_date_dimension';
    $args{driver}     //= 'MySQL';
    $args{columns}    //= [qw[
        id

        day
        month
        year
        quarter

        day_of_week
        day_of_year
        day_of_quarter

        week_of_month
        week_of_year

        is_leap_year
        is_dst
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
            day    => $datetime->day,
            month  => $datetime->month,
            year   => $datetime->year,
        ]
    );
}

1;

__END__
