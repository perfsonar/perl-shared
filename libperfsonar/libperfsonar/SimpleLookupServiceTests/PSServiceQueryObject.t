#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;


use perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject;

my $query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();

#check record creation
ok( defined $query,            "new(record => '$query')" );

#check the class type
ok( $query->isa('perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject'), "class type");


#init() test
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
is($query->init(), 0, "init - basic test");
cmp_deeply($query->toURLParameters(), '?type=service', "toURLParameters" ) ;


#setServiceEventType
my $var = 'http://ggf.org/ns/nmwg/tools/iperf/2.0';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
is($query->setServiceEventType($var), 0, "setServiceEventType string");

$var = ['http://ggf.org/ns/nmwg/tools/iperf/2.0'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
is($query->setServiceEventType($var), 0, "setServiceEventType array");

$var = ['http://ggf.org/ns/nmwg/tools/iperf/2.0', 'http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
is($query->setServiceEventType($var), 0, "setServiceEventType - array >1");


#getServiceEventType
$var = 'http://ggf.org/ns/nmwg/tools/iperf/2.0';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
$query->setServiceEventType($var);
cmp_deeply($query->getServiceEventType(),['http://ggf.org/ns/nmwg/tools/iperf/2.0'], "getServiceEventType - string" );

$var = ['http://ggf.org/ns/nmwg/tools/iperf/2.0'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
$query->setServiceEventType($var);
cmp_deeply($query->getServiceEventType(),$var, "getServiceEventType - array" );

$var = ['http://ggf.org/ns/nmwg/tools/iperf/2.0', 'http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
$query->setServiceEventType($var);
cmp_deeply($query->getServiceEventType(),$var, "getServiceEventType - array > 1" );

#$var = ['http://ggf.org/ns/nmwg/tools/iperf/2.0', 'http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
#$query->setServiceEventType($var);
cmp_deeply($query->getServiceEventType(), undef, "getServiceEventType - undef" );


#setTopologyDomain
$var = 'es.net';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
is($query->setTopologyDomain($var), 0, "setTopologyDomain string");

$var = ['es.net'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
is($query->setTopologyDomain($var), 0, "setTopologyDomain array");

$var = ['es.net', 'lbl.gov'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
is($query->setTopologyDomain($var), 0, "setTopologyDomain - array >1");


#getTopologyDomain
$var = 'es.net';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
$query->setTopologyDomain($var);
cmp_deeply($query->getTopologyDomain(),['es.net'], "getTopologyDomain - string" );

$var = ['es.net'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
$query->setTopologyDomain($var);
cmp_deeply($query->getTopologyDomain(),$var, "getTopologyDomain - array" );

$var = ['es.net', 'lbl.gov'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
$query->setTopologyDomain($var);
cmp_deeply($query->getTopologyDomain(),$var, "getTopologyDomain - array > 1" );

$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
cmp_deeply($query->getTopologyDomain(), undef, "getTopologyDomain - undef" );


#setMAType
$var = 'pscheduler';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
is($query->setMAType($var), 0, "setMAType string");

$var = ['pscheduler'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
is($query->setMAType($var), 0, "setMAType array");

$var = ['pscheduler', 'iperf'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
is($query->setMAType($var), 0, "setMAType - array >1");


#getMAType
$var = 'pscheduler';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
$query->setMAType($var);
cmp_deeply($query->getMAType(),['pscheduler'], "getMAType - string" );

$var = ['pscheduler'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
$query->setMAType($var);
cmp_deeply($query->getMAType(),$var, "getMAType - array" );

$var = ['pscheduler', 'iperf'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
$query->setMAType($var);
cmp_deeply($query->getMAType(),$var, "getMAType - array > 1" );

$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
cmp_deeply($query->getMAType(), undef, "getMAType - undef" );


#setMATests
$var = 'http://localhost:8080/lookup/pstest/abcd-e45-5466777';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
is($query->setMATests($var), 0, "setMATests string");

$var = ['http://localhost:8080/lookup/pstest/abcd-e45-5466777'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
is($query->setMATests($var), 0, "setMATests array");

$var = ['http://localhost:8080/lookup/pstest/abcd-e45-5466777', 'http://localhost:8080/lookup/pstest/abcd-e45-54667234'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
is($query->setMATests($var), 0, "setMATests - array >1");


#getMATests
$var = 'http://localhost:8080/lookup/pstest/abcd-e45-5466777';
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
$query->setMATests($var);
cmp_deeply($query->getMATests(),['http://localhost:8080/lookup/pstest/abcd-e45-5466777'], "getMATests - string" );

$var = ['http://localhost:8080/lookup/pstest/abcd-e45-5466777'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
$query->setMATests($var);
cmp_deeply($query->getMATests(),$var, "getMATests - array" );

$var = ['http://localhost:8080/lookup/pstest/abcd-e45-5466777', 'http://localhost:8080/lookup/pstest/abcd-e45-54667234'];
$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
$query->setMATests($var);
cmp_deeply($query->getMATests(),$var, "getMATests - array > 1" );


$query = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
$query->init();
cmp_deeply($query->getMATests(), undef, "getMATests - undef" );