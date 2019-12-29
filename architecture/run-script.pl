#!/usr/bin/perl
use strict;
use warnings;

# Used modules
use JSON::XS qw(encode_json decode_json);
use Try::Tiny;
use IPC::Open3 qw(open3);
use POSIX ":sys_wait_h";

use constant INPUT_TESTS_FILE => 'input-tests.json';
use constant TEST_FILE => 'runtest';
use constant RESULT_FILE => 'result-data.json';

my $json_tests = parse_json_file(INPUT_TESTS_FILE);

my ($pid, $chld_outline, $chld_proc, $chld_answer); # Used to pass and read the data from test file

my @result_data = (); # Save the result from test script

my $counter = 1; # Counter for input tests

foreach my $input_tests (@{$json_tests}) {
	# Open file for input tests
	try {
		$pid = open3(\*CHLD_WRITE, \*CHLD_READ, 0, './' . TEST_FILE);
	} catch {
		print "Unable to open " . TEST_FILE . " for I/O operations\n";
		exit 4;
	};

	# Send the input string to CHILD STDIN
	foreach my $input_test (@{$input_tests}) {
		print CHLD_WRITE "$input_test\n";
	}

	$chld_answer = '';
	# Read the output from the test script and add it to the array
	while (1) {
		$chld_proc = waitpid($pid, WNOHANG);

		if ($chld_proc == -1) { # Problem with child process
			print "Child process error: " . ($? >> 8);
			exit 5;
		}

		if ($chld_proc) { # Child process is ready
			last;
		}

		$chld_outline = <CHLD_READ>; # Get output line from child process

		if ($chld_outline) {
			$chld_answer .= $chld_outline; # Append and construct the output
		}
	}

	save_current_test_result($chld_answer, $counter);
	$counter++;
}

sub parse_json_file {
	my $json_file = shift;

	# Read the whole json file at once
	my $json_data = do {
		local $/= undef;
		open my $FH, '<', $json_file or do {
			print "Unable to read test file: " . $json_file . "\n";
			exit 2;
		};
		<$FH>;
	};

	# Parse json file into hash
	my $json_tests = {};
	try {
		$json_tests = decode_json($json_data);
	} catch {
		print "Unable to parse " . $json_file . "\n";
		exit 3;
	};

	return $json_tests;
}

# Save the data in result file
sub save_current_test_result {
	my ($result_data, $test_count) = @_;

	# We do not have the file on the first run, so we use an empty hash
	my $json_tests = {};
	if (-f RESULT_FILE) {
		$json_tests = parse_json_file(RESULT_FILE);
	}

	$json_tests->{$test_count} = $result_data;

	my $json_result = encode_json($json_tests); # Create result json

	open my $FH, '>', RESULT_FILE or do {
		print "Unable to write to result file: " . RESULT_FILE . "\n";
		exit 6;
	};

	flock($FH, 2); # Lock the file for other process
	print $FH $json_result;

	close $FH;
}

exit 0;
