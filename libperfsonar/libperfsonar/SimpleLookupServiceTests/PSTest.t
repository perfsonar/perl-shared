#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;


use perfSONAR_PS::Client::LS::PSRecords::PSTest;

my $test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();

#check record creation
ok( defined $test,            "new(record => '$test')" );

#check the class type
ok( $test->isa('perfSONAR_PS::Client::LS::PSRecords::PSTest'), "class type");

# check init()
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });

#setDNSDomains
my $var = 'es.net';
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
is($test->setDNSDomains($var), 0, "setDNSDomains - string");

$var = ['es.net'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
is($test->setDNSDomains($var), 0, "setDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
is($test->setDNSDomains($var), 0, "setDNSDomains - array > 1");


#getDNSDomains
$var = 'es.net';
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
$test->setDNSDomains($var);
cmp_deeply($test->getDNSDomains(), ['es.net'], "getDNSDomains - string");

$var = ['es.net'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
$test->setDNSDomains($var);
cmp_deeply($test->getDNSDomains(), $var, "getDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
$test->setDNSDomains($var);
cmp_deeply($test->getDNSDomains(), $var, "getDNSDomains - array > 1");

$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
cmp_deeply($test->getDNSDomains(), undef, "getDNSDomains - returns null");



#setEventTypes
$var = 'http://ggf.org/ns/nmwg/tools/iperf/2.0';
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
is($test->setEventTypes($var), 0, "setEventTypes string");

$var = ['http://ggf.org/ns/nmwg/tools/iperf/2.0'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
is($test->setEventTypes($var), 0, "setEventTypes array");

$var = ['http://ggf.org/ns/nmwg/tools/iperf/2.0', 'http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
is($test->setEventTypes($var), 0, "setEventTypes - array >1");


#getEventTypes
$var = 'http://ggf.org/ns/nmwg/tools/iperf/2.0';
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
$test->setEventTypes($var);
cmp_deeply($test->getEventTypes(),['http://ggf.org/ns/nmwg/tools/iperf/2.0'], "getEventTypes - string" );

$var = ['http://ggf.org/ns/nmwg/tools/iperf/2.0'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
$test->setEventTypes($var);
cmp_deeply($test->getEventTypes(),$var, "getEventTypes - array" );

$var = ['http://ggf.org/ns/nmwg/tools/iperf/2.0', 'http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
$test->setEventTypes($var);
cmp_deeply($test->getEventTypes(),$var, "getEventTypes - array > 1" );

#$var = ['http://ggf.org/ns/nmwg/tools/iperf/2.0', 'http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
#$test->setEventTypes($var);
cmp_deeply($test->getEventTypes(), undef, "getEventTypes - undef" );


#setCommunities
$var = 'es.net';
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
is($test->setCommunities($var), 0, "setCommunities - string");

$var = ['es.net'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
is($test->setCommunities($var), 0, "setCommunities - array");

$var = ['es.net', 'lbl.gov'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
is($test->setCommunities($var), 0, "setCommunities - array > 1");


#getCommunities
$var = 'ESnet';
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
$test->setCommunities($var);
cmp_deeply($test->getCommunities(), ['ESnet'], "getCommunities - string");

$var = ['ESnet'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
$test->setCommunities($var);
cmp_deeply($test->getCommunities(), $var, "getCommunities - array");

$var = ['ESnet', 'LBL'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
$test->setCommunities($var);
cmp_deeply($test->getCommunities(), $var, "getCommunities - array > 1");

$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
cmp_deeply($test->getCommunities(), undef, "getCommunities - returns null");



#setDestination
$var = 'http://localhost:8080/lookup/host/abcd-e45-54665678';
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
is($test->setDestination($var), 0, "setDestination - string");

$var = ['http://localhost:8080/lookup/host/abcd-e45-54665678'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
is($test->setDestination($var), 0, "setDestination - array");

$var = ['http://localhost:8080/lookup/host/abcd-e45-54665678', 'http://localhost:8080/lookup/host/abcd-e45-54665678'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
is($test->setDestination($var), -1, "setDestination - array > 1");


#getDestination
$var = 'http://localhost:8080/lookup/host/abcd-e45-54665678';
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
$test->setDestination($var);
cmp_deeply($test->getDestination(), ['http://localhost:8080/lookup/host/abcd-e45-54665678'], "getDestination - string");

$var = ['http://localhost:8080/lookup/host/abcd-e45-54665678'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
$test->setDestination($var);
cmp_deeply($test->getDestination(), $var, "getDestination - array");


$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
cmp_deeply($test->getDestination(), undef, "getDestination - returns null");



#setSource
$var = 'http://localhost:8080/lookup/host/abcd-e45-54665678';
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
is($test->setSource($var), 0, "setSource - string");

$var = ['http://localhost:8080/lookup/host/abcd-e45-54665678'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
is($test->setSource($var), 0, "setSource - array");

$var = ['http://localhost:8080/lookup/host/abcd-e45-54665678', 'http://localhost:8080/lookup/host/abcd-e45-54665678'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
is($test->setSource($var), -1, "setSource - array > 1");


#getSource
$var = 'http://localhost:8080/lookup/host/abcd-e45-54665678';
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
$test->setSource($var);
cmp_deeply($test->getSource(), ['http://localhost:8080/lookup/host/abcd-e45-54665678'], "getSource - string");

$var = ['http://localhost:8080/lookup/host/abcd-e45-54665678'];
$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
$test->init({eventType=>'http://ggf.org/ns/nmwg/tools/iperf/2.0', source => 'http://localhost:8080/lookup/host/abcd-e45-5466777', destination => 'http://localhost:8080/lookup/host/abcd-e45-5466778' });
$test->setSource($var);
cmp_deeply($test->getSource(), $var, "getSource - array");


$test = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
cmp_deeply($test->getSource(), undef, "getSource - returns null");