#!/usr/bin/perl
package TestUtils::Runner;
use strict;
use warnings;

use Getopt::Long;
use JSON::XS qw(encode_json decode_json);
use Try::Tiny;
use IPC::Open3 qw(open3);
use POSIX ":sys_wait_h";

use constant INPUT_TESTS_FILE => 'input-tests.json';
use constant RESULT_FILE => 'result-data.json';

my $test_file = '';
GetOptions("test-file|f=s" => \$test_file);

if (!$test_file) {
	print "Missing test file!\n";
	exit 7;
}

sub run_tests {
	my $json_tests = parse_json_file(INPUT_TESTS_FILE);

	my ($pid, $chld_outline, $chld_proc, $chld_answer); # Used to pass and read the data from test file

	my $counter = 1; # Counter for input tests

	foreach my $input_tests (@{$json_tests}) {
		# Open file for input tests
		try {
			$pid = open3(\*CHLD_WRITE, \*CHLD_READ, 0, './' . $test_file);
		} catch {
			print "Unable to open " . $test_file . " for I/O operations\n";
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

sub __main() {
	run_tests();
}

# The following line make the file acts like script
__PACKAGE__->__main() unless caller();

exit 0;

__END__
