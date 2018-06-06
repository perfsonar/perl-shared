#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;

use SimpleLookupService::QueryObjects::Network::ServiceQueryObject;

my $query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();

#check record creation
ok( defined $query,            "new(query => '$query')" );

#check the class type
ok( $query->isa('SimpleLookupService::QueryObjects::Network::ServiceQueryObject'), "and it's the right class");

#init() test
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
is($query->init(), 0, "init - no parameters");



#setServiceName
my $queryName = 'Wash Ping';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setServiceName($queryName), 0, "setServiceName - string");

$queryName = ['Wash Ping'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setServiceName($queryName), 0, "setServiceName - array");

$queryName = ['Wash Ping', 'Ping Wash'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setServiceName($queryName), 0, "setServiceName - array > 1");


#getServiceName 
$queryName = 'Wash Ping';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setServiceName($queryName);
cmp_deeply($query->getServiceName(), ['Wash Ping'], "getServiceName - returns value");

$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
cmp_deeply($query->getServiceName(), undef, "getServiceName - returns null");


#setServiceVersion
my $queryVersion = '3.2.2';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setServiceVersion($queryVersion), 0, "setServiceVersion - string");

$queryVersion = ['3.2.2'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setServiceVersion($queryVersion), 0, "setServiceVersion - array");

$queryVersion = ['3.2.2', '3.2.1'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setServiceVersion($queryVersion), 0, "setServiceVersion - array > 1");


#getServiceVersion
$queryVersion = '3.2.2';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setServiceVersion($queryVersion);
cmp_deeply($query->getServiceVersion(), ['3.2.2'], "getServiceVersion - returns value");

$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
cmp_deeply($query->getServiceVersion(), undef, "getServiceVersion - returns null");


#setServiceType
my $var = 'pscheduler';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setServiceType($var), 0, "setServiceType - string");

$var = ['pscheduler'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setServiceType($var), 0, "setServiceType - array");

$var = ['pscheduler', 'owamp'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setServiceType($var), 0, "setServiceType - array > 1");


#getServiceType
$var = ['ping'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setServiceType($var);
cmp_deeply($query->getServiceType(), ['ping'], "getServiceType - returns value");

$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
cmp_deeply($query->getServiceType(), undef, "getServiceType - returns null");


#setServiceLocators
$var = 'albu-pt1.es.net';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setServiceLocators($var), 0, "setServiceLocator - string");

$var = ['albu-pt1.es.net'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setServiceLocators($var), 0, "setServiceLocator - array");

$var = ['albu-pt1.es.net', 'albu-pt1-v6.es.net'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setServiceLocators($var), 0, "setServiceLocator - array > 1");


#getServiceLocators
$var = 'albu-pt1.es.net';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setServiceLocators($var);
cmp_deeply($query->getServiceLocators(), ['albu-pt1.es.net'], "getServiceLocator - string");

$var = ['albu-pt1.es.net'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setServiceLocators($var);
cmp_deeply($query->getServiceLocators(), $var, "getServiceLocator - array");

$var = ['albu-pt1.es.net', 'albu-pt1-v6.es.net'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setServiceLocators($var);
cmp_deeply($query->getServiceLocators(), $var, "getServiceLocators - array > 1");

$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
cmp_deeply($query->getServiceLocators(), undef, "getServiceLocator - returns null");



#setServiceAdministrators
$var = 'http://localhost:8080/lookup/person/abcd-e45-5466777';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setServiceAdministrators($var), 0, "setServiceAdministrators - string");

$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setServiceAdministrators($var), 0, "setServiceAdministrators - array");

$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777', 'http://localhost:8080/lookup/person/abcd-e45-54667876'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setServiceAdministrators($var), 0, "setServiceAdministrators - array > 1");


#getServiceAdministrators
$var = 'http://localhost:8080/lookup/person/abcd-e45-5466777';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setServiceAdministrators($var);
cmp_deeply($query->getServiceAdministrators(), ['http://localhost:8080/lookup/person/abcd-e45-5466777'], "getServiceAdministrators - string");

$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setServiceAdministrators($var);
cmp_deeply($query->getServiceAdministrators(), $var, "getServiceAdministrators - array");

$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777', 'http://localhost:8080/lookup/person/abcd-e45-5466876'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setServiceAdministrators($var);
cmp_deeply($query->getServiceAdministrators(), $var, "getServiceAdministrators - array > 1");

$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
cmp_deeply($query->getServiceAdministrators(), undef, "getServiceAdministrators - returns null");



#setDNSDomains
$var = 'es.net';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setDNSDomains($var), 0, "setDNSDomains - string");

$var = ['es.net'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setDNSDomains($var), 0, "setDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setDNSDomains($var), 0, "setDNSDomains - array > 1");


#getDNSDomains
$var = 'es.net';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setDNSDomains($var);
cmp_deeply($query->getDNSDomains(), ['es.net'], "getDNSDomains - string");

$var = ['es.net'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setDNSDomains($var);
cmp_deeply($query->getDNSDomains(), $var, "getDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setDNSDomains($var);
cmp_deeply($query->getDNSDomains(), $var, "getDNSDomains - array > 1");

$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
cmp_deeply($query->getDNSDomains(), undef, "getDNSDomains - returns null");



#setSiteName
$var = 'LBL';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setSiteName($var), 0, "setSiteName - string");

$var = ['LBL'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setSiteName($var), 0, "setSiteName - array");

$var = ['LBL', 'LBNL'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setSiteName($var), 0, "setSiteName - array > 1");

#getSiteName
$var = 'LBL';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setSiteName($var);
cmp_deeply($query->getSiteName(), ['LBL'], "getSiteName - string");

$var = ['LBL'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setSiteName($var);
cmp_deeply($query->getSiteName(), $var, "getSiteName - array");

$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
cmp_deeply($query->getSiteName(), undef, "getSiteName - returns null");


#setCity
$var = 'Berkeley';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setCity($var), 0, "setCity - string");

$var = ['Berkeley'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setCity($var), 0, "setCity - array");

$var = ['Berkeley', 'LBNL'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setCity($var), 0, "setCity - array > 1");

#getCity
$var = 'Berkeley';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setCity($var);
cmp_deeply($query->getCity(), ['Berkeley'], "getCity - string");

$var = ['Berkeley'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setCity($var);
cmp_deeply($query->getCity(), $var, "getCity - array");

$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
cmp_deeply($query->getCity(), undef, "getCity - returns null");


#setRegion
$var = 'CA';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setRegion($var), 0, "setRegion - string");

$var = ['CA'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setRegion($var), 0, "setRegion - array");

$var = ['CA', 'WA'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setRegion($var), 0, "setRegion - array > 1");


#getRegion
$var = 'CA';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setRegion($var);
cmp_deeply($query->getRegion(), ['CA'], "getRegion - string");

$var = ['CA'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setRegion($var);
cmp_deeply($query->getRegion(), $var, "getRegion - array");

$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
cmp_deeply($query->getRegion(), undef, "getRegion - returns null");


#setCountry
$var = 'US';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setCountry($var), 0, "setCountry - string");

$var = ['US'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setCountry($var), 0, "setCountry - array");

$var = 'USA';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setCountry($var), 0, "setCountry - not a 2 digit code");

$var = ['USA'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setCountry($var), 0, "setCountry - not a 2 digit code");


$var = ['US', 'UK'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setCountry($var), 0, "setCountry - array > 1");

#getCountry
$var = 'US';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setCountry($var);
cmp_deeply($query->getCountry(), ['US'], "getCountry - string");

$var = ['US'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setCountry($var);
cmp_deeply($query->getCountry(), $var, "getCountry - array");

$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
cmp_deeply($query->getCountry(), undef, "getCountry - returns null");


#setZipCode
$var = '94720';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setZipCode($var), 0, "setZipCode - string");

$var = ['94720'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setZipCode($var), 0, "setZipCode - array");

$var = ['94720', '94724'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setZipCode($var), 0, "setZipCode - array > 1");


#getZipCode
$var = '94720';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setZipCode($var);
cmp_deeply($query->getZipCode(), ['94720'], "getZipCode - string");

$var = ['94720'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setZipCode($var);
cmp_deeply($query->getZipCode(), $var, "getZipCode - array");

$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
cmp_deeply($query->getZipCode(), undef, "getZipCode - returns null");


#setLatitude
$var = '-18';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setLatitude($var), 0, "setLatitude - string");

$var = ['18'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setLatitude($var), 0, "setLatitude - array");

$var = ['95'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setLatitude($var), 0, "setLatitude - not within range");

$var = ['18', '28'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setLatitude($var), 0, "setLatitude - array > 1");

#getLatitude
$var = '-18';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setLatitude($var);
cmp_deeply($query->getLatitude(), ['-18'], "getLatitude - string");

$var = ['-18'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setLatitude($var);
cmp_deeply($query->getLatitude(), $var, "getLatitude - array");

$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
cmp_deeply($query->getLatitude(), undef, "getLatitude - returns null");

#setLongitude
$var = '-18';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setLongitude($var), 0, "setLongitude - string");

$var = ['18'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setLongitude($var), 0, "setLongitude - array");

$var = ['187'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setLongitude($var), 0, "setLongitude - not within range");

$var = ['18', '28'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
is($query->setLongitude($var), 0, "setLongitude - array > 1");

#getLongitude
$var = '-18';
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setLongitude($var);
cmp_deeply($query->getLongitude(), ['-18'], "getLongitude - string");

$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
cmp_deeply($query->getLongitude(), undef, "getLongitude - returns null");

$var = ['-18'];
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setLongitude($var);
cmp_deeply($query->getLongitude(), $var, "getLongitude - array");



#toURLParameters - multiple values
#this test may result in error -  if so check manually
$query = SimpleLookupService::QueryObjects::Network::ServiceQueryObject->new();
$query->init();
$query->setOperator('all');
$query->setRecordTtlInMinutes('60');
$query->setLongitude($var);
is($query->toURLParameters(),'?operator=all&ttl=60&location-longitude=-18&type=service',"toURLParameters - parameters as array");