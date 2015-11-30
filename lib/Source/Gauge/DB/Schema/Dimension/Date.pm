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

        epoch
    ]]}
);

sub generate_data_as_csv {
    my ($self, $fh, %opts) = @_;

    my $start_year = $opts{'start'} // die 'You must specify a `start` year';
    my $end_year   = $opts{'end'}   // die 'You must specify a `end` year';

    my $current = DateTime->from_day_of_year( year => $start_year, day_of_year => 1 );
    my $count   = 0;

    while ( $current->year <= $end_year ) {
        print $fh (
            join ',' =>
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
                $current->epoch,
            ), "\n"
        ;
        $current->add( days => 1 );
        $count++;
    }

    return $count;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
