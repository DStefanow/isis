#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
use FindBin;

=begin comment_section

This test script is for Runner.pm who is
used as script to run user test code.

=cut

BEGIN {
	use lib "$FindBin::RealBin/../../architecture/";
	require_ok('TestUtils::Runner');
}
