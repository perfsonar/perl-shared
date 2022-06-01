#!/usr/bin/perl

use strict;
use warnings;

my %manifest_files = ();
my %found_files    = ();

open(MANIFEST, "MANIFEST") or die("Couldn't open MANIFEST");
while(<MANIFEST>) {
	chomp;
	s/^\.\///;
	$manifest_files{$_} = 1;
}
close(MANIFEST);


open(FILES, "-|", "find . | grep -v \\.svn") or die("Couldn't open MANIFEST");
while(<FILES>) {
	chomp;
	s/^\.\///;

	next if ($_ eq "lib");
	next if (-d $_);

	$found_files{$_} = 1;
}
close(FILES);

print "Missing Files:\n";
foreach my $file (sort keys %manifest_files) {
	next if (-f $file);
	next if (-l $file);

	print $file."\n";
}

print "Unpackaged Files:\n";
foreach my $file (sort keys %found_files) {
	if (not $manifest_files{$file}) {
		print $file."\n";
	}
}
