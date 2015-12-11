package Source::Gauge::DB::Schema::Dimension::Date;
use Moose;

use DateTime;

extends 'SQL::Combine::Table';

has '+name'       => ( default => 'Dimension::Date' );
has '+table_name' => ( default => 'sg_date_dimension' );
has '+driver'     => ( default => 'MySQL' );
has '+columns'    => (
    default => sub {[qw[
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
    ]]}
);

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

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
