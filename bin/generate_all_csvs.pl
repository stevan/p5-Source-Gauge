#!/usr/bin/perl

use lib 'lib';

use strict;
use warnings;

use Source::Gauge::Script::DB::GenerateAllCSVs;

Source::Gauge::Script::DB::GenerateAllCSVs->new_with_options->run;

1;
