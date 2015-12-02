package Source::Gauge::Script;
use Moose::Role;

with 'MooseX::Getopt';

has 'verbose' => ( is => 'ro', isa => 'Bool', default => 0 );

sub log {
    my ($self, $fmt, @rest) = @_;
    return unless $self->verbose;
    print STDERR (sprintf $fmt => @rest), "\n";
}

no Moose::Role; 1;

__END__
