package Source::Gauge::DB::Schema::Dimension::Time;
use Moose;

use DateTime;

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

sub generate_data_as_csv {
    my ($self, $fh, %opts) = @_;

    my $current = DateTime->from_epoch( epoch => 0 );
    my $today   = $current->day;
    my $count   = 0;

    while ( $current->day == $today ) {
        print $fh (
            join ',' =>
                $current->hour,
                $current->minute,
                $current->second,
            ), "\n"
        ;
        $current->add( seconds => 1 );
        $count++;
    }

    return $count;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
