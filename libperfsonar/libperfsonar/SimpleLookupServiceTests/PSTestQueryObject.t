#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;


use perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject;

my $query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();

#check record creation
ok( defined $query,            "new(record => '$query')" );

#check the class type
ok( $query->isa('perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject'), "class type");


$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
is($query->init(), 0, "init - check");

#setDNSDomains
my $var = 'es.net';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
is($query->setDNSDomains($var), 0, "setDNSDomains - string");

$var = ['es.net'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
is($query->setDNSDomains($var), 0, "setDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
is($query->setDNSDomains($var), 0, "setDNSDomains - array > 1");


#getDNSDomains
$var = 'es.net';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
$query->setDNSDomains($var);
cmp_deeply($query->getDNSDomains(), ['es.net'], "getDNSDomains - string");

$var = ['es.net'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
$query->setDNSDomains($var);
cmp_deeply($query->getDNSDomains(), $var, "getDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
$query->setDNSDomains($var);
cmp_deeply($query->getDNSDomains(), $var, "getDNSDomains - array > 1");

$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
cmp_deeply($query->getDNSDomains(), undef, "getDNSDomains - returns null");



#setEventTypes
$var = 'http://ggf.org/ns/nmwg/tools/iperf/2.0';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
is($query->setEventTypes($var), 0, "setEventTypes string");

$var = ['http://ggf.org/ns/nmwg/tools/iperf/2.0'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
is($query->setEventTypes($var), 0, "setEventTypes array");

$var = ['http://ggf.org/ns/nmwg/tools/iperf/2.0', 'http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
is($query->setEventTypes($var), 0, "setEventTypes - array >1");


#getEventTypes
$var = 'http://ggf.org/ns/nmwg/tools/iperf/2.0';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
$query->setEventTypes($var);
cmp_deeply($query->getEventTypes(),['http://ggf.org/ns/nmwg/tools/iperf/2.0'], "getEventTypes - string" );

$var = ['http://ggf.org/ns/nmwg/tools/iperf/2.0'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
$query->setEventTypes($var);
cmp_deeply($query->getEventTypes(),$var, "getEventTypes - array" );

$var = ['http://ggf.org/ns/nmwg/tools/iperf/2.0', 'http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
$query->setEventTypes($var);
cmp_deeply($query->getEventTypes(),$var, "getEventTypes - array > 1" );

#$var = ['http://ggf.org/ns/nmwg/tools/iperf/2.0', 'http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
#$query->setEventTypes($var);
cmp_deeply($query->getEventTypes(), undef, "getEventTypes - undef" );


#setCommunities
$var = 'es.net';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
is($query->setCommunities($var), 0, "setCommunities - string");

$var = ['es.net'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
is($query->setCommunities($var), 0, "setCommunities - array");

$var = ['es.net', 'lbl.gov'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
is($query->setCommunities($var), 0, "setCommunities - array > 1");


#getCommunities
$var = 'ESnet';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
$query->setCommunities($var);
cmp_deeply($query->getCommunities(), ['ESnet'], "getCommunities - string");

$var = ['ESnet'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
$query->setCommunities($var);
cmp_deeply($query->getCommunities(), $var, "getCommunities - array");

$var = ['ESnet', 'LBL'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
$query->setCommunities($var);
cmp_deeply($query->getCommunities(), $var, "getCommunities - array > 1");

$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
cmp_deeply($query->getCommunities(), undef, "getCommunities - returns null");



#setDestination
$var = 'http://localhost:8080/lookup/host/abcd-e45-54665678';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
is($query->setDestination($var), 0, "setDestination - string");

$var = ['http://localhost:8080/lookup/host/abcd-e45-54665678'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
is($query->setDestination($var), 0, "setDestination - array");

$var = ['http://localhost:8080/lookup/host/abcd-e45-54665678', 'http://localhost:8080/lookup/host/abcd-e45-54665678'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
is($query->setDestination($var), -1, "setDestination - array > 1");


#getDestination
$var = 'http://localhost:8080/lookup/host/abcd-e45-54665678';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
$query->setDestination($var);
cmp_deeply($query->getDestination(), ['http://localhost:8080/lookup/host/abcd-e45-54665678'], "getDestination - string");

$var = ['http://localhost:8080/lookup/host/abcd-e45-54665678'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
$query->setDestination($var);
cmp_deeply($query->getDestination(), $var, "getDestination - array");


$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
cmp_deeply($query->getDestination(), undef, "getDestination - returns null");



#setSource
$var = 'http://localhost:8080/lookup/host/abcd-e45-54665678';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
is($query->setSource($var), 0, "setSource - string");

$var = ['http://localhost:8080/lookup/host/abcd-e45-54665678'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
is($query->setSource($var), 0, "setSource - array");

$var = ['http://localhost:8080/lookup/host/abcd-e45-54665678', 'http://localhost:8080/lookup/host/abcd-e45-54665678'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
is($query->setSource($var), -1, "setSource - array > 1");


#getSource
$var = 'http://localhost:8080/lookup/host/abcd-e45-54665678';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
$query->setSource($var);
cmp_deeply($query->getSource(), ['http://localhost:8080/lookup/host/abcd-e45-54665678'], "getSource - string");

$var = ['http://localhost:8080/lookup/host/abcd-e45-54665678'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
$query->init();
$query->setSource($var);
cmp_deeply($query->getSource(), $var, "getSource - array");
cmp_deeply($query->toURLParameters(), "?pstest-source=http://localhost:8080/lookup/host/abcd-e45-54665678&type=pstest", "toURLParameters");


$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
cmp_deeply($query->getSource(), undef, "getSource - returns null");