package Source::Gauge::Script::DB::Generator::DateTimeDimensions;
use Moose;

use MooseX::Types::Path::Class;
use Path::Class ();

use Text::CSV_XS;

use DateTime;
use DateTime::Format::Strptime;

with 'Source::Gauge::Script';

has 'dir' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    required => 1,
    coerce   => 1,
);

has 'start_date' => ( is => 'ro', isa => 'Str', required => 1 );
has 'end_date'   => ( is => 'ro', isa => 'Str', predicate => 'has_end_date' );

has 'time_dimension_filename' => ( is => 'ro', isa => 'Str', default => 'time_dimension.csv' );
has 'date_dimension_filename' => ( is => 'ro', isa => 'Str', default => 'date_dimension.csv' );

sub run {
    my $self = shift;

    my $date_formatter = DateTime::Format::Strptime->new( pattern => '%F' );

    my $dir   = $self->dir;
    my $start = $date_formatter->parse_datetime( $self->start_date );
    my $end   = $self->has_end_date
        ? $date_formatter->parse_datetime( $self->end_date )
        : DateTime->now;

    $self->log('Generating CSVs into dir: %s', $dir);
    my $time_csv = $dir->file( $self->time_dimension_filename );
    my $date_csv = $dir->file( $self->date_dimension_filename );

    $self->log('Start generating time CSV (%s)' => $time_csv);
    $self->generate_time_diemsnsion_data_as_csv( fh => $time_csv->openw );
    $self->log('Finish generating time CSV');

    $self->log('Start generating date CSV (%s) with start(%s) and end(%s)' => $time_csv, $start, $end);
    $self->generate_date_dimension_data_as_csv(
        fh    => $date_csv->openw,
        start => $start,
        end   => $end,
    );
    $self->log('Finish generating date CSV');

    return;
}

## ...

sub generate_time_diemsnsion_data_as_csv {
    my ($self, %opts) = @_;

    my $fh = $opts{fh} // \*STDOUT;

    my $csv     = Text::CSV_XS->new ({ binary => 1, eol => $/ });
    my $current = DateTime->from_epoch( epoch => 0 );
    my $today   = $current->day;
    my $count   = 0;

    while ( $current->day == $today ) {
        $csv->print(
            $fh,
            [
                $current->hour,
                $current->minute,
                $current->second,
            ]
        );
        $current->add( seconds => 1 );
        $count++;
    }

    return $count;
}

sub generate_date_dimension_data_as_csv {
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
