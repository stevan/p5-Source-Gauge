#!/usr/bin/perl

use lib 'lib';

use strict;
use warnings;

use Source::Gauge::Script::DB::Importer::GitCommitRange;

Source::Gauge::Script::DB::Importer::GitCommitRange->new_with_options->run;

1;
