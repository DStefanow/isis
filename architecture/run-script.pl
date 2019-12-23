#!/usr/bin/perl
use strict;
use warnings;

# Used modules
use JSON::XS qw(encode_json decode_json);
use IPC::Open3 qw(open3);

use constant JSON_FILE => 'input-tests.json';
use constant TEST_FILE => 'test.pl';
use constant RESULT_FILE => 'result-data.json';

# Read the whole json file
my $json_file = do {
	local $/= undef;
	open my $FH, '<', JSON_FILE
		or do die("Unable to read test file: " . JSON_FILE . "\n");
	<$FH>;
};

# Parse json file into hash
my $json_tests = decode_json($json_file);

my ($pid, $chld_answer); # Used to pass and read the data from test file

my @result_data = (); # Save the result from test script

foreach my $input_tests (@{$json_tests}) {
	$pid = open3(\*CHLD_WRITE, \*CHLD_READ, 0, './' . TEST_FILE) or die("Unable to open " . TEST_FILE .
		" for I/O operations\n"); # Open file for input tests

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
open my $FH, '>', RESULT_FILE or do die("Unable to write to result file: " . RESULT_FILE . "\n");
print $FH $json_result;
close $FH;

exit 0;
