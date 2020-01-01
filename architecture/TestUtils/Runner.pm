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
	log_error("Missing test file: $test_file!", 7);
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
			log_error("Unable to open $test_file for I/O operations", 4);
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
				log_error("Child process error: " . ($? >> 8), 5);
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
			log_error("Unable to read test file: " . $json_file, 2);
		};
		<$FH>;
	};

	# Parse json file into hash
	my $json_tests = {};
	try {
		$json_tests = decode_json($json_data);
	} catch {
		log_error("Unable to parse $json_file", 3);
	};

	return $json_tests;
}

# Save the data in result file
sub save_current_test_result {
	my ($result_data, $test_count) = @_;

	# We do not have the file on the first run, so we use an empty hash
	my $json_data = {};
	if (-f RESULT_FILE) {
		$json_data = parse_json_file(RESULT_FILE);
	}

	$json_data->{results}->{$test_count} = $result_data;

	my $json_result = encode_json($json_data); # Create result json

	save_json_in_file($json_data, RESULT_FILE);
}

sub log_error {
	my $err_msg = shift;
	my $err_code = shift;

	# We do not have the file on the first run, so we use an empty hash
	my $json_data = {};
	if (-f RESULT_FILE) {
		$json_data = parse_json_file(RESULT_FILE);
	}

	$json_data->{error} = {
		'error_msg' => $err_msg,
		'error_code' => $err_code
	};

	save_json_in_file($json_data, RESULT_FILE);

	exit $err_code;
}

sub save_json_in_file {
	my $json_data = shift;
	my $json_file = shift;

	my $json_result = encode_json($json_data); # Create result json

	open my $FH, '>', $json_file or do {
		log_error("Unable to write to result file: $json_file", 6);
	};

	flock($FH, 2); # Lock the file for other process
	print $FH $json_result;

	close $FH;

	return 1;
}

sub __main() {
	run_tests();
}

# The following line make the file acts like script
__PACKAGE__->__main() unless caller();

exit 0;

__END__
