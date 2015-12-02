package Source::Gauge::DB::Schema::Dimension::Date;
use Moose;

use DateTime;
use Text::CSV_XS;

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
    return $self->select(
        columns => [ $self->primary_key, @additional_columns ],
        where   => [
            day    => $datetime->day,
            month  => $datetime->month,
            year   => $datetime->year,
        ]
    );
}

sub generate_data_as_csv {
    my ($self, %opts) = @_;

    my $fh    = $opts{fh}    // \*STDOUT;
    my $start = $opts{start} // confess 'You must specify a `start` date';
    my $end   = $opts{end}   // DateTime->now;

    # TODO:
    # check that start date is before end date

    my $csv     = Text::CSV_XS->new ({ binary => 1, eol => $/ });
    my $current = $start;
    my $count   = 0;

    while ( $current <= $end ) {
        $csv->print(
            $fh,
            [
                $current->day,
                $current->month,
                $current->year,
                $current->quarter,
                $current->day_of_week,
                $current->day_of_year,
                $current->day_of_quarter,
                $current->week_of_month,
                $current->week_number,
                $current->is_leap_year,
                $current->is_dst,
            ]
        );
        $current->add( days => 1 );
        $count++;
    }

    return $count;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
