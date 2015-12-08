#!/usr/bin/perl

use lib 'lib';

use strict;
use warnings;

use Source::Gauge::Script::DB::Generator::DateTimeDimensions;

Source::Gauge::Script::DB::Generator::DateTimeDimensions->new_with_options->run;

1;
