#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;

use SimpleLookupService::Records::Record;

use SimpleLookupService::Utils::Time qw(minutes_to_iso iso_to_minutes is_iso iso_to_unix);


#_is_iso
my $ts = "PT30M";
is(is_iso($ts), 1, "is_iso() - returns true");

$ts = "60";
is(is_iso($ts), 0, "is_iso() - returns true");


#_iso_to_minutes
$ts = "PT30M";
is(iso_to_minutes($ts), 30, "iso_to_minutes() - returns 30");

$ts = "PT30W";
is(iso_to_minutes($ts), undef, "iso_to_minutes() - returns undef");

$ts = " ";
is(iso_to_minutes($ts), undef, "iso_to_minutes() - returns undef");


#_minutes_to_iso

$ts = "30";
is(minutes_to_iso($ts), 'PT30M', "minutes_to_iso() - returns PT30M");

$ts = "PT30M";
is(minutes_to_iso($ts), undef, "minutes_to_iso() - returns undef");

$ts = '';
is(minutes_to_iso($ts), undef, "minutes_to_iso() - returns undef");

#_isoToUnix
$ts = "2012-12-17T10:14:03.208Z";
is(iso_to_unix($ts), '1355739243', "isToUnix() - returns 1355739243");

1;