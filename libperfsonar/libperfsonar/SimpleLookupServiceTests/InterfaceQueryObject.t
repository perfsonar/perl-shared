#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;

use SimpleLookupService::QueryObjects::Network::InterfaceQueryObject;

my $query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();

#check record creation
ok( defined $query,            "new(query => '$query')" );

#check the class type
ok( $query->isa('SimpleLookupService::QueryObjects::Network::InterfaceQueryObject'), "and it's the right class");

#init() test
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
is($query->init(), 0, "init - no parameters");


#setInterfaceName
my $queryName = 'wash-pt1.es.net';
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceName($queryName), 0, "setInterfaceName - string");

$queryName = ['wash-pt1.es.net'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceName($queryName), 0, "setInterfaceName - array");

$queryName = ['wash-pt1.es.net', 'wash-pt1-v6.es.net'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceName($queryName), 0, "setInterfaceName - array > 1");


#getInterfaceName 
$queryName = 'wash-pt1.es.net';
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
$query->setInterfaceName($queryName);
cmp_deeply($query->getInterfaceName(), ['wash-pt1.es.net'], "getInterfaceName - returns value");

$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
cmp_deeply($query->getInterfaceName(), undef, "getInterfaceName - returns null");


#setInterfaceAddresses
my $var = '192.0.0.2';
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceAddresses($var), 0, "setInterfaceAddresses - string");

$queryName = ['192.0.0.2'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceAddresses($queryName), 0, "setInterfaceAddresses - array");

$queryName = ['192.0.0.2', '192.0.0.3'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceAddresses($queryName), 0, "setInterfaceAddresses - array > 1");


#getInterfaceAddresses 
$queryName = '192.0.0.1';
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
$query->setInterfaceAddresses($queryName);
cmp_deeply($query->getInterfaceAddresses(), ['192.0.0.1'], "getInterfaceAddresses - returns value");

$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
cmp_deeply($query->getInterfaceAddresses(), undef, "getInterfaceAddresses - returns null");


#setInterfaceSubnet
$var = '192.0.0.2';
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceSubnet($queryName), 0, "setInterfaceSubnet - string");

$queryName = ['192.0.0.2'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceSubnet($queryName), 0, "setInterfaceSubnet - array");

$queryName = ['192.0.0.2', '192.0.0.3'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceSubnet($queryName), 0, "setInterfaceSubnet - array > 1");


#getInterfaceSubnet 
$queryName = ['192.0.0.1'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
$query->setInterfaceSubnet($queryName);
cmp_deeply($query->getInterfaceSubnet(), ['192.0.0.1'], "getInterfaceSubnet - returns value");

$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
cmp_deeply($query->getInterfaceSubnet(), undef, "getInterfaceSubnet - returns null");



#setInterfaceCapacity
$var = '1024';
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceCapacity($var), 0, "setInterfaceCapacity - string");

$var = 1024;
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceCapacity($var), 0, "setInterfaceCapacity - integer");

$var = ['1024'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceCapacity($var), 0, "setInterfaceCapacity - array");

$var = [1024];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceCapacity($var), 0, "setInterfaceCapacity - integer array");

$var = ['512', '1024'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceCapacity($var), 0, "setInterfaceCapacity - array > 1");

$var = [512, 1024];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceCapacity($var), 0, "setInterfaceCapacity - integer array > 1");


#getInterfaceCapacity
$var = '1024';
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
$query->setInterfaceCapacity($var);
cmp_deeply($query->getInterfaceCapacity(), ['1024'], "getInterfaceCapacity -  string val");

$var = 1024;
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
$query->setInterfaceCapacity($var);
cmp_deeply($query->getInterfaceCapacity(), [1024], "getInterfaceCapacity - integer val");

$var = ['1024'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
$query->setInterfaceCapacity($var);
cmp_deeply($query->getInterfaceCapacity(), $var, "getInterfaceCapacity - string array");

$var = [1024];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
$query->setInterfaceCapacity($var);
cmp_deeply($query->getInterfaceCapacity(), $var, "getInterfaceCapacity - integer array");

$var = ['512', '1024'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
$query->setInterfaceCapacity($var);
cmp_deeply($query->getInterfaceCapacity(), $var, "getInterfaceCapacity - string array > 1");

$var = [512, 1024];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
$query->setInterfaceCapacity($var);
cmp_deeply($query->getInterfaceCapacity(), $var, "getInterfaceCapacity - integer array > 1");


#setInterfaceMacAddress
$var = '01:23:45:67:89:ab';
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceMacAddress($var), 0, "setInterfaceMacAddress - string");

$var = ['01:23:45:67:89:ab'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceMacAddress($var), 0, "setInterfaceMacAddress - array");

$var = ['01:23:45:67:89:ab', '01:23:45:67:89:ab'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setInterfaceMacAddress($var), 0, "setInterfaceMacAddress - array > 1");


#getInterfaceMacAddress 
$var = ['01:23:45:67:89:ab'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
$query->setInterfaceMacAddress($var);
cmp_deeply($query->getInterfaceMacAddress(), $var, "getInterfaceMacAddress - returns value");

$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
cmp_deeply($query->getInterfaceMacAddress(), undef, "getInterfaceMacAddress - returns null");


#setDNSDomains
$var = 'es.net';
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setDNSDomains($var), 0, "setDNSDomains - string");

$var = ['es.net'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setDNSDomains($var), 0, "setDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
is($query->setDNSDomains($var), 0, "setDNSDomains - array > 1");


#getDNSDomains
$var = 'es.net';
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
$query->setDNSDomains($var);
cmp_deeply($query->getDNSDomains(), ['es.net'], "getDNSDomains - string");

$var = ['es.net'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
$query->setDNSDomains($var);
cmp_deeply($query->getDNSDomains(), $var, "getDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
$query->init();
$query->setDNSDomains($var);
cmp_deeply($query->getDNSDomains(), $var, "getDNSDomains - array > 1");

$query = SimpleLookupService::QueryObjects::Network::InterfaceQueryObject->new();
cmp_deeply($query->getDNSDomains(), undef, "getDNSDomains - returns null");