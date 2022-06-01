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

		my $output;

		print "Tidying $file\n";

		system("perltidy -profile=$Bin/Shared/doc/perltidyrc $file > $file.tdy");

		next if ($? != 0);

		system("cp -L $file.tdy $file");
		system("rm $file.tdy");
}
