#!/usr/bin/perl

use FindBin qw($Bin);

my $level = 3;

my %errors = ();
my @files = `find | grep -v \\\.svn`;

foreach my $file (@files) {
		chomp($file);

        my $type = `file -b $file`;

		# Skip non-Perl files
        next unless ($file =~ /\.pm$/ or $file =~ /\.pl$/ or $type =~ /Perl/ or $type =~ /perl/ or $file =~ /\.cgi/);

		print STDERR "Critiquing $file\n";

		my $output;

		open(CRITIC, "-|", "perlcritic -$level -profile $Bin/Shared/doc/perlcritic $file");
		while(<CRITIC>) {
			$output .= $_;
		}
		close(CRITIC);

		next if ($output =~ /OK/);

		$errors{$file} = $output;
}

foreach my $file (keys %errors) {
	print "-------------------------------------------------------------\n";
	print $file."\n";
	print "-------------------------------------------------------------\n";
	print $errors{$file};
}
