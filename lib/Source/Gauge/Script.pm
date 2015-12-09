package Source::Gauge::Script;
use Moose::Role;

use Data::Dumper ();

with 'MooseX::Getopt';

has 'dry_run' => ( is => 'ro', isa => 'Bool', default => 0 );
has 'verbose' => ( is => 'ro', isa => 'Bool', default => 0 );

sub log {
    my ($self, $fmt, @rest) = @_;
    return unless $self->verbose;
    print STDERR (sprintf $fmt => @rest), "\n";
}

sub log_data {
    my ($self, $data) = @_;
    $self->log('%s', Data::Dumper->new( $data )->Indent(0)->Dump );
}

no Moose::Role; 1;

__END__
