#!/usr/bin/perl

use lib 'lib';

use strict;
use warnings;

use Source::Gauge::Script::DB::ImportCommits;

Source::Gauge::Script::DB::ImportCommits->new_with_options->run;

1;
