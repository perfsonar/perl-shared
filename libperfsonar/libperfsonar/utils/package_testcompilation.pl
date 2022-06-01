#!/usr/bin/perl

use Module::Load;

use lib 'lib';

my %errors = ();
my @modules = `find lib -iname '*.pm' | grep perfSONAR_PS | sed -e 's/.*lib\\///' | sed -e 's/.pm//' | sed -e 's/\\//::/g'`;
foreach my $module (@modules) {
	chomp($module);

	eval {
		use lib 'lib';
		load $module;
	};
	if ($@) {
		$errors{$module} = $@;
	}
}
foreach my $module (keys %errors) {
	print "$module Failed: ".$errors{$module}."\n";
}
