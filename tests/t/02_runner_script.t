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
	use_ok('TestUtils::Runner', qw(run_tests parse_json_file save_current_test_result log_error save_json_in_file));
}

subtest 'save_json_in_file tests' => sub {
	plan tests => 1;

	my $result_code;
	my $result_test_file = 'tests/t/data/tmp/result-test.json'; # Save the data from tests

	# Valid json - the file should be created
	$result_code = save_json_in_file({ ping => 'pong' }, $result_test_file) or diag("Unable to create json file: $result_test_file");
	is($result_code, 1, 'Valid json - file created');
};

1;
