#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

=begin comment_section

This test script is for all needed modules
used in test script, api section and etc.
If a new module is added in some of the
scripts/modules we need to add it here to
be able to check if the production enviroment
has it.

=cut

# All modules, add a new module here
my @modules = ('JSON::XS', 'Try::Tiny', 'IPC::Open3', 'POSIX', 'Getopt::Long', 'Pod::Usage');
my $modules_count = @modules;

diag("Going to check for $modules_count installed modules!\n");

foreach my $module (@modules) {
	require_ok($module) or prove("Cannot continue testing because module - $module is missing on current system\n");
}

exit 0;
