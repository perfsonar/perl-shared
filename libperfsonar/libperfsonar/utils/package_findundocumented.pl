#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw($Bin);

my $level = 3;

my %functions = ();
my @files = `find | grep -v \\\.svn`;

foreach my $file (@files) {
		chomp($file);

        my $type = `file -b $file`;

		# Skip non-Perl files
        next unless ($file =~ /\.pm$/ or $file =~ /\.pl$/ or $type =~ /Perl/ or $type =~ /perl/ or $file =~ /\.cgi/);

		print STDERR "Checking $file\n";

		my $output;

		my @lines = ();
		open(GREP, "-|", "grep -B 5 '^sub ' $file");
		while(<GREP>) {
			chomp;
			push @lines, $_;
		}
		close(GREP);

		if ($#lines == 0) {
			print STDERR "No lines in $file\n";
			next;
		}

		my @functions = ();

		for(my $i = 0; $i <= $#lines; $i++) {
			if ($lines[$i] =~ /^sub ([a-zA-Z0-9_-]*)/) {
				my $function = $1;

				unless ($lines[$i-1] =~ /=cut/ or $lines[$i-2] =~ /=cut/) {
					# check for the end of comments, if it's not in the
					# previous two lines, assume it doesn't exist. perltidy
					# should handle this case.

					push @functions, $function;
					next;
				}

				for(my $j = $i; $j >= $i-5; $j--) {
					if ($lines[$j] =~ /TBD/) {
						push @functions, $function;
					}
				}
			}
		}

		if (scalar(@functions) > 0) {
			$functions{$file} = \@functions;
		}
}

foreach my $file (keys %functions) {
	print "-------------------------------------------------------------\n";
	print $file."\n";
	print "-------------------------------------------------------------\n";
	foreach my $function (@{ $functions{$file} }) {
		print $function."\n";
	}
}
