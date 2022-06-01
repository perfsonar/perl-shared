#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;

use SimpleLookupService::QueryObjects::Directory::PersonQueryObject;

my $query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();

#check record creation
ok( defined $query,            "new(query => '$query')" );

#check the class type
ok( $query->isa('SimpleLookupService::QueryObjects::Directory::PersonQueryObject'), "and it's the right class");

#init() test
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
is($query->init(), 0, "init - no parameters");


#setPersonName
my $var = 'Bill';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setPersonName($var), 0, "setPersonName - string");

$var = ['Bill'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setPersonName($var), 0, "setPersonName - array");

$var = ['Bill', 'William'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setPersonName($var), 0, "setPersonName - array > 1");

#getPersonName
$var = 'Bill';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setPersonName($var);
cmp_deeply($query->getPersonName(), ['Bill'], "getPersonName - string");

$var = ['Bill'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setPersonName($var);
cmp_deeply($query->getPersonName(), $var, "getPersonName - array");

$var = ['Bill', 'William'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setPersonName($var);
cmp_deeply($query->getPersonName(), $var, "getPersonName - array > 1");

$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
cmp_deeply($query->getPersonName(), undef, "getPersonName - returns null");


#setEmailAddresses
$var = 'adam1@es.net';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setEmailAddresses($var), 0, "setEmailAddresses - string");

$var = ['adam1@es.net'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setEmailAddresses($var), 0, "setEmailAddresses - array");

$var = ['adam1@es.net', 'adam12@es.net'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setEmailAddresses($var), 0, "setEmailAddresses - array > 1");

#getEmailAddresses
$var = 'adam1@es.net';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setEmailAddresses($var);
cmp_deeply($query->getEmailAddresses(), ['adam1@es.net'], "getEmailAddresses - string");

$var = ['adam1@es.net'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setEmailAddresses($var);
cmp_deeply($query->getEmailAddresses(), $var, "getEmailAddresses - array");

$var = ['adam1@es.net', 'adam2@es.net'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setEmailAddresses($var);
cmp_deeply($query->getEmailAddresses(), $var, "getEmailAddresses - array > 1");

$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
cmp_deeply($query->getEmailAddresses(), undef, "getEmailAddresses - returns null");


#setPhoneNumbers
$var = '5103451234';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setPhoneNumbers($var), 0, "setPhoneNumbers - string");

$var = ['5103451234'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setPhoneNumbers($var), 0, "setPhoneNumbers - array");

$var = ['5103451234', '5103451234'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setPhoneNumbers($var), 0, "setPhoneNumbers - array > 1");

#getPhoneNumbers
$var = '5103451234';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setPhoneNumbers($var);
cmp_deeply($query->getPhoneNumbers(), ['5103451234'], "getPhoneNumbers - string");

$var = ['5103451234'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setPhoneNumbers($var);
cmp_deeply($query->getPhoneNumbers(), $var, "getPhoneNumbers - array");

$var = ['5103451234', '5103451235'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setPhoneNumbers($var);
cmp_deeply($query->getPhoneNumbers(), $var, "getPhoneNumbers - array > 1");

$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
cmp_deeply($query->getPhoneNumbers(), undef, "getPhoneNumbers - returns null");


#setOrganization
$var = 'LBL';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setOrganization($var), 0, "setOrganization - string");

$var = ['LBL'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setOrganization($var), 0, "setOrganization - array");

$var = ['LBL', 'LBNL'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setOrganization($var), 0, "setOrganization - array > 1");

#getOrganization
$var = 'LBL';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setOrganization($var);
cmp_deeply($query->getOrganization(), ['LBL'], "getOrganization - string");

$var = ['LBL'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setOrganization($var);
cmp_deeply($query->getOrganization(), $var, "getOrganization - array");

$var = ['LBL', 'LBNL'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setOrganization($var);
cmp_deeply($query->getOrganization(), $var, "getOrganization - array > 1");

$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
cmp_deeply($query->getOrganization(), undef, "getOrganization - returns null");


#setSiteName
$var = 'LBL';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setSiteName($var), 0, "setSiteName - string");

$var = ['LBL'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setSiteName($var), 0, "setSiteName - array");

$var = ['LBL', 'LBNL'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setSiteName($var), 0, "setSiteName - array > 1");

#getSiteName
$var = 'LBL';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setSiteName($var);
cmp_deeply($query->getSiteName(), ['LBL'], "getSiteName - string");

$var = ['LBL'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setSiteName($var);
cmp_deeply($query->getSiteName(), $var, "getSiteName - array");

$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
cmp_deeply($query->getSiteName(), undef, "getSiteName - returns null");


#setCity
$var = 'Berkeley';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setCity($var), 0, "setCity - string");

$var = ['Berkeley'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setCity($var), 0, "setCity - array");

$var = ['Berkeley', 'LBNL'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setCity($var), 0, "setCity - array > 1");

#getCity
$var = 'Berkeley';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setCity($var);
cmp_deeply($query->getCity(), ['Berkeley'], "getCity - string");

$var = ['Berkeley'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setCity($var);
cmp_deeply($query->getCity(), $var, "getCity - array");

$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
cmp_deeply($query->getCity(), undef, "getCity - returns null");


#setRegion
$var = 'CA';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setRegion($var), 0, "setRegion - string");

$var = ['CA'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setRegion($var), 0, "setRegion - array");

$var = ['CA', 'WA'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setRegion($var), 0, "setRegion - array > 1");


#getRegion
$var = 'CA';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setRegion($var);
cmp_deeply($query->getRegion(), ['CA'], "getRegion - string");

$var = ['CA'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setRegion($var);
cmp_deeply($query->getRegion(), $var, "getRegion - array");

$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
cmp_deeply($query->getRegion(), undef, "getRegion - returns null");


#setCountry
$var = 'US';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setCountry($var), 0, "setCountry - string");

$var = ['US'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setCountry($var), 0, "setCountry - array");

$var = 'USA';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setCountry($var), 0, "setCountry - not a 2 digit code");

$var = ['USA'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setCountry($var), 0, "setCountry - not a 2 digit code");


$var = ['US', 'UK'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setCountry($var), 0, "setCountry - array > 1");

#getCountry
$var = 'US';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setCountry($var);
cmp_deeply($query->getCountry(), ['US'], "getCountry - string");

$var = ['US'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setCountry($var);
cmp_deeply($query->getCountry(), $var, "getCountry - array");

$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
cmp_deeply($query->getCountry(), undef, "getCountry - returns null");


#setZipCode
$var = '94720';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setZipCode($var), 0, "setZipCode - string");

$var = ['94720'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setZipCode($var), 0, "setZipCode - array");

$var = ['94720', '94724'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setZipCode($var), 0, "setZipCode - array > 1");


#getZipCode
$var = '94720';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setZipCode($var);
cmp_deeply($query->getZipCode(), ['94720'], "getZipCode - string");

$var = ['94720'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setZipCode($var);
cmp_deeply($query->getZipCode(), $var, "getZipCode - array");

$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
cmp_deeply($query->getZipCode(), undef, "getZipCode - returns null");


#setLatitude
$var = '-18';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setLatitude($var), 0, "setLatitude - string");

$var = ['18'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setLatitude($var), 0, "setLatitude - array");

$var = ['95'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setLatitude($var), 0, "setLatitude - not within range");

$var = ['18', '28'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setLatitude($var), 0, "setLatitude - array > 1");

#getLatitude
$var = '-18';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setLatitude($var);
cmp_deeply($query->getLatitude(), ['-18'], "getLatitude - string");

$var = ['-18'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setLatitude($var);
cmp_deeply($query->getLatitude(), $var, "getLatitude - array");

$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
cmp_deeply($query->getLatitude(), undef, "getLatitude - returns null");

#setLongitude
$var = '-18';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setLongitude($var), 0, "setLongitude - string");

$var = ['18'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setLongitude($var), 0, "setLongitude - array");

$var = ['187'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setLongitude($var), 0, "setLongitude - not within range");

$var = ['18', '28'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
is($query->setLongitude($var), 0, "setLongitude - array > 1");

#getLongitude
$var = '-18';
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setLongitude($var);
cmp_deeply($query->getLongitude(), ['-18'], "getLongitude - string");

$var = ['-18'];
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setLongitude($var);
cmp_deeply($query->getLongitude(), $var, "getLongitude - array");


$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
cmp_deeply($query->getLongitude(), undef, "getLongitude - returns null");


#toURLParameters - multiple values
#this test may result in error -  if so check manually
$query = SimpleLookupService::QueryObjects::Directory::PersonQueryObject->new();
$query->init();
$query->setOperator('all');
$query->setRecordTtlInMinutes('60');
$query->setLongitude($var);
$query->setEmailAddresses("adam\@es.net");
is($query->toURLParameters(),'?operator=all&ttl=60&location-longitude=-18&person-emails=adam@es.net&type=person',"toURLParameters - parameters as array");
