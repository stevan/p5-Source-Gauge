package Source::Gauge::DB::Schema;
use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use Source::Gauge::DB::Schema::Commit;
use Source::Gauge::DB::Schema::Commit::Author;
use Source::Gauge::DB::Schema::Commit::File;

use Source::Gauge::DB::Schema::Dimension::Time;
use Source::Gauge::DB::Schema::Dimension::Date;

use Source::Gauge::DB::Schema::FileSystem;

use parent 'SQL::Combine::Schema';

sub new {
    my ($class, %args) = @_;

    $args{name}   //= 'sg';
    $args{tables} //= [
        Source::Gauge::DB::Schema::Commit->new,
        Source::Gauge::DB::Schema::Commit::Author->new,
        Source::Gauge::DB::Schema::Commit::File->new,
        Source::Gauge::DB::Schema::Dimension::Time->new,
        Source::Gauge::DB::Schema::Dimension::Date->new,
        Source::Gauge::DB::Schema::FileSystem->new,
    ];

    return $class->SUPER::new( %args );
}

1;

__END__
