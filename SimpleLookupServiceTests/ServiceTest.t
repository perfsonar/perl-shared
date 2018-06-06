#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;


use SimpleLookupService::Records::Network::Service;

my $service = SimpleLookupService::Records::Network::Service->new();

#check record creation
ok( defined $service,            "new(record => '$service')" );

#check the class type
ok( $service->isa('SimpleLookupService::Records::Network::Service'), "class type");

#init() test
$service = SimpleLookupService::Records::Network::Service->new();
is($service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'}), 0, "init - basic test");
is($service->init({serviceLocator => 'wash-pt1.es.net', serviceType =>'ping', serviceName => 'Wash ping', serviceVersion => '3.2', 
    									domains => ['es.net', 'lbl.gov'], administrators => ['http://localhost:8080/lookup/person/abcd-e45-5466777'], 
    									siteName => 'LBL' , city => 'Berkeley', region => 'CA',
    									country => 'US', zipCode => '94720', latitude =>['-18'], longitude => ['18']}), 0, "init - optional parameters");
cmp_deeply($service->toJson(), '{"service-administrators":["http://localhost:8080/lookup/person/abcd-e45-5466777"],"location-city":["Berkeley"],"group-domains":["es.net","lbl.gov"],"location-longitude":["18"],"location-state":["CA"],"service-version":["3.2"],"service-name":["Wash ping"],"location-sitename":["LBL"],"location-code":["94720"],"location-country":["US"],"location-latitude":["-18"],"type":["service"],"service-type":["ping"],"service-locator":["wash-pt1.es.net"]}', "toJson()" ) ;


#setServiceName
my $serviceName = 'Wash Ping';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setServiceName($serviceName), 0, "setServiceName - string");

$serviceName = ['Wash Ping'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setServiceName($serviceName), 0, "setServiceName - array");

$serviceName = ['Wash Ping', 'Ping Wash'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setServiceName($serviceName), -1, "setServiceName - array > 1");


#getServiceName 
$serviceName = 'Wash Ping';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', serviceName => $serviceName});
cmp_deeply($service->getServiceName(), ['Wash Ping'], "getServiceName - returns value");

$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
cmp_deeply($service->getServiceName(), undef, "getServiceName - returns null");


#setServiceVersion
my $serviceVersion = '3.2.2';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setServiceVersion($serviceVersion), 0, "setServiceVersion - string");

$serviceVersion = ['3.2.2'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setServiceVersion($serviceVersion), 0, "setServiceVersion - array");

$serviceVersion = ['3.2.2', '3.2.1'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setServiceVersion($serviceVersion), -1, "setServiceVersion - array > 1");


#getServiceVersion
$serviceVersion = '3.2.2';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', serviceVersion => $serviceVersion});
cmp_deeply($service->getServiceVersion(), ['3.2.2'], "getServiceVersion - returns value");

$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
cmp_deeply($service->getServiceVersion(), undef, "getServiceVersion - returns null");


#setServiceType
my $var = 'pscheduler';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setServiceType($var), 0, "setServiceType - string");

$var = ['pscheduler'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setServiceType($var), 0, "setServiceType - array");

$var = ['pscheduler', 'owamp'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setServiceType($var), -1, "setServiceType - array > 1");


#getServiceType
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
cmp_deeply($service->getServiceType(), ['ping'], "getServiceType - returns value");

$service = SimpleLookupService::Records::Network::Service->new();
cmp_deeply($service->getServiceType(), undef, "getServiceType - returns null");


#setServiceLocators
$var = 'albu-pt1.es.net';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setServiceLocators($var), 0, "setServiceLocator - string");

$var = ['albu-pt1.es.net'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setServiceLocators($var), 0, "setServiceLocator - array");

$var = ['albu-pt1.es.net', 'albu-pt1-v6.es.net'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setServiceLocators($var), 0, "setServiceLocator - array > 1");


#getServiceLocators
$var = 'albu-pt1.es.net';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>$var, serviceType => 'ping'});
cmp_deeply($service->getServiceLocators(), ['albu-pt1.es.net'], "getServiceLocator - string");

$var = ['albu-pt1.es.net'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>$var, serviceType => 'ping'});
cmp_deeply($service->getServiceLocators(), $var, "getServiceLocator - array");

$var = ['albu-pt1.es.net', 'albu-pt1-v6.es.net'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>$var, serviceType => 'ping'});
cmp_deeply($service->getServiceLocators(), $var, "getServiceLocators - array > 1");

$service = SimpleLookupService::Records::Network::Service->new();
cmp_deeply($service->getServiceLocators(), undef, "getServiceLocator - returns null");



#setServiceAdministrators
$var = 'http://localhost:8080/lookup/person/abcd-e45-5466777';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setServiceAdministrators($var), 0, "setServiceAdministrators - string");

$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setServiceAdministrators($var), 0, "setServiceAdministrators - array");

$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777', 'http://localhost:8080/lookup/person/abcd-e45-54667876'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setServiceAdministrators($var), 0, "setServiceAdministrators - array > 1");


#getServiceAdministrators
$var = 'http://localhost:8080/lookup/person/abcd-e45-5466777';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', administrators => $var});
cmp_deeply($service->getServiceAdministrators(), ['http://localhost:8080/lookup/person/abcd-e45-5466777'], "getServiceAdministrators - string");

$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', administrators => $var});
cmp_deeply($service->getServiceAdministrators(), $var, "getServiceAdministrators - array");

$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777', 'http://localhost:8080/lookup/person/abcd-e45-5466876'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', administrators => $var});
cmp_deeply($service->getServiceAdministrators(), $var, "getServiceAdministrators - array > 1");

$service = SimpleLookupService::Records::Network::Service->new();
cmp_deeply($service->getServiceAdministrators(), undef, "getServiceAdministrators - returns null");



#setDNSDomains
$var = 'es.net';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setDNSDomains($var), 0, "setDNSDomains - string");

$var = ['es.net'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setDNSDomains($var), 0, "setDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setDNSDomains($var), 0, "setDNSDomains - array > 1");


#getDNSDomains
$var = 'es.net';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', domains => $var});
cmp_deeply($service->getDNSDomains(), ['es.net'], "getDNSDomains - string");

$var = ['es.net'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', domains => $var});
cmp_deeply($service->getDNSDomains(), $var, "getDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', domains => $var});
cmp_deeply($service->getDNSDomains(), $var, "getDNSDomains - array > 1");

$service = SimpleLookupService::Records::Network::Service->new();
cmp_deeply($service->getDNSDomains(), undef, "getDNSDomains - returns null");



#setSiteName
$var = 'LBL';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setSiteName($var), 0, "setSiteName - string");

$var = ['LBL'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setSiteName($var), 0, "setSiteName - array");

$var = ['LBL', 'LBNL'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setSiteName($var), -1, "setSiteName - array > 1");

#getSiteName
$var = 'LBL';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', siteName => $var});
cmp_deeply($service->getSiteName(), ['LBL'], "getSiteName - string");

$var = ['LBL'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', siteName => $var});
cmp_deeply($service->getSiteName(), $var, "getSiteName - array");

$service = SimpleLookupService::Records::Network::Service->new();
cmp_deeply($service->getSiteName(), undef, "getSiteName - returns null");


#setCity
$var = 'Berkeley';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setCity($var), 0, "setCity - string");

$var = ['Berkeley'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setCity($var), 0, "setCity - array");

$var = ['Berkeley', 'LBNL'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setCity($var), -1, "setCity - array > 1");

#getCity
$var = 'Berkeley';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', city => $var});
cmp_deeply($service->getCity(), ['Berkeley'], "getCity - string");

$var = ['Berkeley'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', city => $var});
cmp_deeply($service->getCity(), $var, "getCity - array");

$service = SimpleLookupService::Records::Network::Service->new();
cmp_deeply($service->getCity(), undef, "getCity - returns null");


#setRegion
$var = 'CA';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setRegion($var), 0, "setRegion - string");

$var = ['CA'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setRegion($var), 0, "setRegion - array");

$var = ['CA', 'WA'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setRegion($var), -1, "setRegion - array > 1");


#getRegion
$var = 'CA';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', region => $var});
cmp_deeply($service->getRegion(), ['CA'], "getRegion - string");

$var = ['CA'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', region => $var});
cmp_deeply($service->getRegion(), $var, "getRegion - array");

$service = SimpleLookupService::Records::Network::Service->new();
cmp_deeply($service->getRegion(), undef, "getRegion - returns null");


#setCountry
$var = 'US';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setCountry($var), 0, "setCountry - string");

$var = ['US'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setCountry($var), 0, "setCountry - array");

$var = 'USA';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setCountry($var), -1, "setCountry - not a 2 digit code");

$var = ['USA'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setCountry($var), -1, "setCountry - not a 2 digit code");


$var = ['US', 'UK'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setCountry($var), -1, "setCountry - array > 1");

#getCountry
$var = 'US';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', country => $var});
cmp_deeply($service->getCountry(), ['US'], "getCountry - string");

$var = ['US'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', country => $var});
cmp_deeply($service->getCountry(), $var, "getCountry - array");

$service = SimpleLookupService::Records::Network::Service->new();
cmp_deeply($service->getCountry(), undef, "getCountry - returns null");


#setZipCode
$var = '94720';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setZipCode($var), 0, "setZipCode - string");

$var = ['94720'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setZipCode($var), 0, "setZipCode - array");

$var = ['94720', '94724'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setZipCode($var), -1, "setZipCode - array > 1");


#getZipCode
$var = '94720';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', zipCode => $var});
cmp_deeply($service->getZipCode(), ['94720'], "getZipCode - string");

$var = ['94720'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', zipCode => $var});
cmp_deeply($service->getZipCode(), $var, "getZipCode - array");

$service = SimpleLookupService::Records::Network::Service->new();
cmp_deeply($service->getZipCode(), undef, "getZipCode - returns null");


#setLatitude
$var = '-18';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setLatitude($var), 0, "setLatitude - string");

$var = ['18'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setLatitude($var), 0, "setLatitude - array");

$var = ['95'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setLatitude($var), -1, "setLatitude - not within range");

$var = ['18', '28'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setLatitude($var), -1, "setLatitude - array > 1");

#getLatitude
$var = '-18';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', latitude => $var});
cmp_deeply($service->getLatitude(), ['-18'], "getLatitude - string");

$var = ['-18'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', latitude => $var});
cmp_deeply($service->getLatitude(), $var, "getLatitude - array");

$service = SimpleLookupService::Records::Network::Service->new();
cmp_deeply($service->getLatitude(), undef, "getLatitude - returns null");

#setLongitude
$var = '-18';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setLongitude($var), 0, "setLongitude - string");

$var = ['18'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setLongitude($var), 0, "setLongitude - array");

$var = ['187'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setLongitude($var), -1, "setLongitude - not within range");

$var = ['18', '28'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping'});
is($service->setLongitude($var), -1, "setLongitude - array > 1");

#getLongitude
$var = '-18';
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', longitude => $var});
cmp_deeply($service->getLongitude(), ['-18'], "getLongitude - string");

$service = SimpleLookupService::Records::Network::Service->new();
cmp_deeply($service->getLongitude(), undef, "getLongitude - returns null");

$var = ['-18'];
$service = SimpleLookupService::Records::Network::Service->new();
$service->init({serviceLocator=>'wash-pt1.es.net', serviceType => 'ping', longitude => $var});
cmp_deeply($service->getLongitude(), $var, "getLongitude - array");

