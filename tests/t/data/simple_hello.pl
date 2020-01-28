use strict;
use warnings;

print "Enter first name: ";
my $first_name = <STDIN>;
chomp $first_name;

print "Enter second name: ";
my $second_name = <STDIN>;
chomp $second_name;

print "Hello!\n";
print "Your first name is $first_name!\n";
print "And your second name is: $second_name!\n";
