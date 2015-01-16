#!perl

use strict;
use warnings;
use feature ':5.10';

main();

sub main {
	my @inputs;
	while(<STDIN>) {
		last if m{^\.$};
		push @inputs => $_;
	}

	foreach my $i (0 .. $#inputs - 1) {
		say sprintf '|%s|%s', $inputs[$i], $inputs[$i + 1];
	}
}
