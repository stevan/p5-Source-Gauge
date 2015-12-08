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

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
