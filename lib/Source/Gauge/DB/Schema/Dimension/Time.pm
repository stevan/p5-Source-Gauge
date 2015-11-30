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

sub table_definition {
    my ($self) = @_;
    my $table_name = $self->table_name;
    return qq[
        CREATE TABLE IF NOT EXISTS `$table_name` (
            `id`     INT     UNSIGNED NOT NULL AUTO_INCREMENT,
            `second` TINYINT UNSIGNED NOT NULL,
            `minute` TINYINT UNSIGNED NOT NULL,
            `hour`   TINYINT UNSIGNED NOT NULL,
            PRIMARY KEY(`id`)
        );
    ];
}

sub generate_csv_data {
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
