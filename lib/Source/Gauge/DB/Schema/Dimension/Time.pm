package Source::Gauge::DB::Schema::Dimension::Time;
use Moose;

use DateTime;
use Text::CSV_XS;

extends 'SQL::Combine::Table';

has '+name'       => ( default => 'Dimension::Time' );
has '+table_name' => ( default => 'sg_time_dimension' );
has '+driver'     => ( default => 'MySQL' );
has '+columns'    => (
    default => sub {[qw[
        id

        second
        minute
        hour
    ]]}
);

sub select_id_by_datetime {
    my ($self, $datetime, @additional_columns) = @_;
    return $self->select(
        columns => [ $self->primary_key, @additional_columns ],
        where   => [
            second => $datetime->second,
            minute => $datetime->minute,
            hour   => $datetime->hour,
        ]
    );
}

sub generate_data_as_csv {
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

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
