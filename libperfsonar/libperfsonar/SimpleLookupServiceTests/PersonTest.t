use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;


use SimpleLookupService::Records::Directory::Person;

my $person = SimpleLookupService::Records::Directory::Person->new();
my $var ='';
#check record creation
ok( defined $person,            "new(record => '$person')" );

#check the class type
ok( $person->isa('SimpleLookupService::Records::Directory::Person'), "class type");

#init() test
$person = SimpleLookupService::Records::Directory::Person->new();
is($person->init({personName=>'Adam', emails => 'adam@es.net'}), 0, "init - basic test");

$person = SimpleLookupService::Records::Directory::Person->new();
is($person->init({personName=>'Adam', emails => 'adam@es.net', phoneNumbers => '408123456', organization => 'LBL',
    									siteName => 'LBL' , city => 'Berkeley', region => 'CA',
    									country => 'US', zipCode => '94720', latitude =>'-18', longitude => '-180'}), 0, "init - all parameters");

#setPersonName
$var = 'Bill';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setPersonName($var), 0, "setPersonName - string");

$var = ['Bill'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setPersonName($var), 0, "setPersonName - array");

$var = ['Bill', 'William'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setPersonName($var), 0, "setPersonName - array > 1");

#getPersonName
$var = 'Bill';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setPersonName($var);
cmp_deeply($person->getPersonName(), ['Bill'], "getPersonName - string");

$var = ['Bill'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setPersonName($var);
cmp_deeply($person->getPersonName(), $var, "getPersonName - array");

$var = ['Bill', 'William'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setPersonName($var);
cmp_deeply($person->getPersonName(), $var, "getPersonName - array > 1");

$person = SimpleLookupService::Records::Directory::Person->new();
cmp_deeply($person->getPersonName(), undef, "getPersonName - returns null");


#setEmailAddresses
$var = 'adam1@es.net';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setEmailAddresses($var), 0, "setEmailAddresses - string");

$var = ['adam1@es.net'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setEmailAddresses($var), 0, "setEmailAddresses - array");

$var = ['adam1@es.net', 'adam12@es.net'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setEmailAddresses($var), 0, "setEmailAddresses - array > 1");

#getEmailAddresses
$var = 'adam1@es.net';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setEmailAddresses($var);
cmp_deeply($person->getEmailAddresses(), ['adam1@es.net'], "getEmailAddresses - string");

$var = ['adam1@es.net'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setEmailAddresses($var);
cmp_deeply($person->getEmailAddresses(), $var, "getEmailAddresses - array");

$var = ['adam1@es.net', 'adam2@es.net'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setEmailAddresses($var);
cmp_deeply($person->getEmailAddresses(), $var, "getEmailAddresses - array > 1");

$person = SimpleLookupService::Records::Directory::Person->new();
cmp_deeply($person->getEmailAddresses(), undef, "getEmailAddresses - returns null");


#setPhoneNumbers
$var = '5103451234';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setPhoneNumbers($var), 0, "setPhoneNumbers - string");

$var = ['5103451234'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setPhoneNumbers($var), 0, "setPhoneNumbers - array");

$var = ['5103451234', '5103451234'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setPhoneNumbers($var), 0, "setPhoneNumbers - array > 1");

#getPhoneNumbers
$var = '5103451234';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setPhoneNumbers($var);
cmp_deeply($person->getPhoneNumbers(), ['5103451234'], "getPhoneNumbers - string");

$var = ['5103451234'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setPhoneNumbers($var);
cmp_deeply($person->getPhoneNumbers(), $var, "getPhoneNumbers - array");

$var = ['5103451234', '5103451235'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setPhoneNumbers($var);
cmp_deeply($person->getPhoneNumbers(), $var, "getPhoneNumbers - array > 1");

$person = SimpleLookupService::Records::Directory::Person->new();
cmp_deeply($person->getPhoneNumbers(), undef, "getPhoneNumbers - returns null");


#setOrganization
$var = 'LBL';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setOrganization($var), 0, "setOrganization - string");

$var = ['LBL'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setOrganization($var), 0, "setOrganization - array");

$var = ['LBL', 'LBNL'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setOrganization($var), 0, "setOrganization - array > 1");

#getOrganization
$var = 'LBL';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setOrganization($var);
cmp_deeply($person->getOrganization(), ['LBL'], "getOrganization - string");

$var = ['LBL'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setOrganization($var);
cmp_deeply($person->getOrganization(), $var, "getOrganization - array");

$var = ['LBL', 'LBNL'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setOrganization($var);
cmp_deeply($person->getOrganization(), $var, "getOrganization - array > 1");

$person = SimpleLookupService::Records::Directory::Person->new();
cmp_deeply($person->getOrganization(), undef, "getOrganization - returns null");


#setSiteName
$var = 'LBL';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setSiteName($var), 0, "setSiteName - string");

$var = ['LBL'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setSiteName($var), 0, "setSiteName - array");

$var = ['LBL', 'LBNL'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setSiteName($var), -1, "setSiteName - array > 1");

#getSiteName
$var = 'LBL';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setSiteName($var);
cmp_deeply($person->getSiteName(), ['LBL'], "getSiteName - string");

$var = ['LBL'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setSiteName($var);
cmp_deeply($person->getSiteName(), $var, "getSiteName - array");

$person = SimpleLookupService::Records::Directory::Person->new();
cmp_deeply($person->getSiteName(), undef, "getSiteName - returns null");


#setCity
$var = 'Berkeley';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setCity($var), 0, "setCity - string");

$var = ['Berkeley'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setCity($var), 0, "setCity - array");

$var = ['Berkeley', 'LBNL'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setCity($var), -1, "setCity - array > 1");

#getCity
$var = 'Berkeley';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setCity($var);
cmp_deeply($person->getCity(), ['Berkeley'], "getCity - string");

$var = ['Berkeley'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setCity($var);
cmp_deeply($person->getCity(), $var, "getCity - array");

$person = SimpleLookupService::Records::Directory::Person->new();
cmp_deeply($person->getCity(), undef, "getCity - returns null");


#setRegion
$var = 'CA';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setRegion($var), 0, "setRegion - string");

$var = ['CA'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setRegion($var), 0, "setRegion - array");

$var = ['CA', 'WA'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setRegion($var), -1, "setRegion - array > 1");


#getRegion
$var = 'CA';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setRegion($var);
cmp_deeply($person->getRegion(), ['CA'], "getRegion - string");

$var = ['CA'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setRegion($var);
cmp_deeply($person->getRegion(), $var, "getRegion - array");

$person = SimpleLookupService::Records::Directory::Person->new();
cmp_deeply($person->getRegion(), undef, "getRegion - returns null");


#setCountry
$var = 'US';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setCountry($var), 0, "setCountry - string");

$var = ['US'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setCountry($var), 0, "setCountry - array");

$var = 'USA';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setCountry($var), -1, "setCountry - not a 2 digit code");

$var = ['USA'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setCountry($var), -1, "setCountry - not a 2 digit code");


$var = ['US', 'UK'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setCountry($var), -1, "setCountry - array > 1");

#getCountry
$var = 'US';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setCountry($var);
cmp_deeply($person->getCountry(), ['US'], "getCountry - string");

$var = ['US'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setCountry($var);
cmp_deeply($person->getCountry(), $var, "getCountry - array");

$person = SimpleLookupService::Records::Directory::Person->new();
cmp_deeply($person->getCountry(), undef, "getCountry - returns null");


#setZipCode
$var = '94720';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setZipCode($var), 0, "setZipCode - string");

$var = ['94720'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setZipCode($var), 0, "setZipCode - array");

$var = ['94720', '94724'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setZipCode($var), -1, "setZipCode - array > 1");


#getZipCode
$var = '94720';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setZipCode($var);
cmp_deeply($person->getZipCode(), ['94720'], "getZipCode - string");

$var = ['94720'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setZipCode($var);
cmp_deeply($person->getZipCode(), $var, "getZipCode - array");

$person = SimpleLookupService::Records::Directory::Person->new();
cmp_deeply($person->getZipCode(), undef, "getZipCode - returns null");


#setLatitude
$var = '-18';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setLatitude($var), 0, "setLatitude - string");

$var = ['18'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setLatitude($var), 0, "setLatitude - array");

$var = ['95'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setLatitude($var), -1, "setLatitude - not within range");

$var = ['18', '28'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setLatitude($var), -1, "setLatitude - array > 1");

#getLatitude
$var = '-18';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setLatitude($var);
cmp_deeply($person->getLatitude(), ['-18'], "getLatitude - string");

$var = ['-18'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setLatitude($var);
cmp_deeply($person->getLatitude(), $var, "getLatitude - array");

$person = SimpleLookupService::Records::Directory::Person->new();
cmp_deeply($person->getLatitude(), undef, "getLatitude - returns null");

#setLongitude
$var = '-18';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setLongitude($var), 0, "setLongitude - string");

$var = ['18'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setLongitude($var), 0, "setLongitude - array");

$var = ['187'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setLongitude($var), -1, "setLongitude - not within range");

$var = ['18', '28'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
is($person->setLongitude($var), -1, "setLongitude - array > 1");

#getLongitude
$var = '-18';
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setLongitude($var);
cmp_deeply($person->getLongitude(), ['-18'], "getLongitude - string");

$var = ['-18'];
$person = SimpleLookupService::Records::Directory::Person->new();
$person->init({personName=>'Adam', emails => 'adam@es.net'});
$person->setLongitude($var);
cmp_deeply($person->getLongitude(), $var, "getLongitude - array");

$person = SimpleLookupService::Records::Directory::Person->new();
cmp_deeply($person->getLongitude(), undef, "getLongitude - returns null");