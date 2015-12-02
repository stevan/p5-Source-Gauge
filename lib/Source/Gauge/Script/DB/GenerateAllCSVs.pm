package Source::Gauge::Script::DB::GenerateAllCSVs;
use Moose;

use MooseX::Types::Path::Class;
use DateTime::Format::Strptime;

use Source::Gauge::DB::Schema::Dimension::Time;
use Source::Gauge::DB::Schema::Dimension::Date;

with 'Source::Gauge::Script';

has 'dir' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    required => 1,
    coerce   => 1,
);

has 'start_date' => ( is => 'ro', isa => 'Str', required => 1 );
has 'end_date'   => ( is => 'ro', isa => 'Str', predicate => 'has_end_date' );

sub run {
    my $self = shift;

    my $date_formatter = DateTime::Format::Strptime->new( pattern => '%F' );

    my $dir   = $self->dir;
    my $start = $date_formatter->parse_datetime( $self->start_date );
    my $end   = $self->has_end_date
        ? $date_formatter->parse_datetime( $self->end_date )
        : DateTime->now;

    $self->log('Generating CSVs into dir: %s', $dir);

    my $time_table = Source::Gauge::DB::Schema::Dimension::Time->new;
    my $time_csv   = $dir->file( $time_table->table_name . '.csv' );

    $self->log('Start generating time CSV (%s)' => $time_csv);
    $time_table->generate_data_as_csv( fh => $time_csv->openw );
    $self->log('Finish generating time CSV');

    my $date_table = Source::Gauge::DB::Schema::Dimension::Date->new;
    my $date_csv   = $dir->file( $date_table->table_name . '.csv' );

    $self->log('Start generating date CSV (%s) with start(%s) and end(%s)' => $time_csv, $start, $end);
    $date_table->generate_data_as_csv(
        fh    => $date_csv->openw,
        start => $start,
        end   => $end,
    );
    $self->log('Finish generating date CSV');

    return;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
