#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib/");
use Test::More 'no_plan';
use Test::Deep;


use SimpleLookupService::Records::RecordFactory;

my $types = ['service', 'person', 'interface', 'host'];

foreach my $type (@{$types}){
	print $type,"\n";
	my $record = SimpleLookupService::Records::RecordFactory->instantiate($type);
	my $var='';
	#check record creation
	ok( defined $record,            "$record" );
}

