#!/usr/bin/perl

use lib 'lib';

use strict;
use warnings;

use Source::Gauge::Script::DB::Importer::RootDirectory;

Source::Gauge::Script::DB::Importer::RootDirectory->new_with_options->run;

1;
