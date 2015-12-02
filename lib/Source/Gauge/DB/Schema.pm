package Source::Gauge::DB::Schema;
use Moose;

use Source::Gauge::DB::Schema::Commit;
use Source::Gauge::DB::Schema::Commit::Author;

use Source::Gauge::DB::Schema::Dimension::Time;
use Source::Gauge::DB::Schema::Dimension::Date;

extends 'SQL::Combine::Schema';

has '+name'   => ( default => 'sg' );
has '+tables' => (
    default => sub {
        return +[
            Source::Gauge::DB::Schema::Commit->new,
            Source::Gauge::DB::Schema::Commit::Author->new,
            Source::Gauge::DB::Schema::Dimension::Time->new,
            Source::Gauge::DB::Schema::Dimension::Date->new,
        ]
    }
);


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__
