#!/usr/bin/perl
use strict;
use warnings;

# Used modules
use JSON::XS qw(encode_json decode_json);
use Try::Tiny;
use IPC::Open3 qw(open3);
use POSIX ":sys_wait_h";

use constant JSON_FILE => 'input-tests.json';
use constant TEST_FILE => 'runtest';
use constant RESULT_FILE => 'result-data.json';

# Read the whole json file
my $json_file = do {
	local $/= undef;
	open my $FH, '<', JSON_FILE or do {
		print "Unable to read test file: " . JSON_FILE . "\n";
		exit 2;
	};
	<$FH>;
};

# Parse json file into hash
my $json_tests = {};
try {
	$json_tests = decode_json($json_file);
} catch {
	print "Unable to parse " . JSON_FILE . "\n";
	exit 3;
};

my ($pid, $chld_answer); # Used to pass and read the data from test file

my @result_data = (); # Save the result from test script

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

	# Read the output from the test script and add it to the array
	chomp($chld_answer = <CHLD_READ>);
	push @result_data, $chld_answer;
}

my $json_result = encode_json(\@result_data); # Turn the result into json

# Save the data in result file
open my $FH, '>', RESULT_FILE or do {
	print "Unable to write to result file: " . RESULT_FILE . "\n";
	exit 5;
};

print $FH $json_result;
close $FH;

exit 0;
