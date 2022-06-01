#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;


use SimpleLookupService::Records::Network::Interface;

my $interface = SimpleLookupService::Records::Network::Interface->new();
my $var ='';
#check record creation
ok( defined $interface,            "new(record => '$interface')" );

#check the class type
ok( $interface->isa('SimpleLookupService::Records::Network::Interface'), "class type");

#init() test
$interface = SimpleLookupService::Records::Network::Interface->new();
is($interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'}), 0, "init - basic test");

$interface = SimpleLookupService::Records::Network::Interface->new();
is($interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1', subnet => '192.0.0.1', capacity => 10000, macAddress=>'01:23:45:67:89:ab', domains=>"es.net"}), 0, "init - all parameters");

#setInterfaceName
my $interfaceName = 'wash-pt1.es.net';
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceName($interfaceName), 0, "setInterfaceName - string");

$interfaceName = ['wash-pt1.es.net'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceName($interfaceName), 0, "setInterfaceName - array");

$interfaceName = ['wash-pt1.es.net', 'wash-pt1-v6.es.net'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceName($interfaceName), 0, "setInterfaceName - array > 1");


#getInterfaceName 
$interfaceName = 'wash-pt1.es.net';
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
cmp_deeply($interface->getInterfaceName(), ['wash-pt1.es.net'], "getInterfaceName - returns value");

$interface = SimpleLookupService::Records::Network::Interface->new();
cmp_deeply($interface->getInterfaceName(), undef, "getInterfaceName - returns null");


#setInterfaceAddresses
$var = '192.0.0.2';
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceAddresses($interfaceName), 0, "setInterfaceAddresses - string");

$interfaceName = ['192.0.0.2'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceAddresses($interfaceName), 0, "setInterfaceAddresses - array");

$interfaceName = ['192.0.0.2', '192.0.0.3'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceAddresses($interfaceName), 0, "setInterfaceAddresses - array > 1");


#getInterfaceAddresses 
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
cmp_deeply($interface->getInterfaceAddresses(), ['192.0.0.1'], "getInterfaceAddresses - returns value");

$interface = SimpleLookupService::Records::Network::Interface->new();
cmp_deeply($interface->getInterfaceAddresses(), undef, "getInterfaceAddresses - returns null");


#setInterfaceSubnet
$var = '192.0.0.2';
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceSubnet($interfaceName), 0, "setInterfaceSubnet - string");

$interfaceName = ['192.0.0.2'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceSubnet($interfaceName), 0, "setInterfaceSubnet - array");

$interfaceName = ['192.0.0.2', '192.0.0.3'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceSubnet($interfaceName), 0, "setInterfaceSubnet - array > 1");


#getInterfaceSubnet 
$interfaceName = ['192.0.0.1'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
$interface->setInterfaceSubnet($interfaceName);
cmp_deeply($interface->getInterfaceSubnet(), ['192.0.0.1'], "getInterfaceSubnet - returns value");

$interface = SimpleLookupService::Records::Network::Interface->new();
cmp_deeply($interface->getInterfaceSubnet(), undef, "getInterfaceSubnet - returns null");



#setInterfaceCapacity
$var = '1024';
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceCapacity($var), 0, "setInterfaceCapacity - string");

$var = 1024;
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceCapacity($var), 0, "setInterfaceCapacity - integer");

$var = ['1024'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceCapacity($var), 0, "setInterfaceCapacity - array");

$var = [1024];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceCapacity($var), 0, "setInterfaceCapacity - integer array");

$var = ['512', '1024'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceCapacity($var), 0, "setInterfaceCapacity - array > 1");

$var = [512, 1024];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceCapacity($var), 0, "setInterfaceCapacity - integer array > 1");


#getInterfaceCapacity
$var = '1024';
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
$interface->setInterfaceCapacity($var);
cmp_deeply($interface->getInterfaceCapacity(), ['1024'], "getInterfaceCapacity -  string val");

$var = 1024;
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
$interface->setInterfaceCapacity($var);
cmp_deeply($interface->getInterfaceCapacity(), [1024], "getInterfaceCapacity - integer val");

$var = ['1024'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
$interface->setInterfaceCapacity($var);
cmp_deeply($interface->getInterfaceCapacity(), $var, "getInterfaceCapacity - string array");

$var = [1024];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
$interface->setInterfaceCapacity($var);
cmp_deeply($interface->getInterfaceCapacity(), $var, "getInterfaceCapacity - integer array");

$var = ['512', '1024'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
$interface->setInterfaceCapacity($var);
cmp_deeply($interface->getInterfaceCapacity(), $var, "getInterfaceCapacity - string array > 1");

$var = [512, 1024];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
$interface->setInterfaceCapacity($var);
cmp_deeply($interface->getInterfaceCapacity(), $var, "getInterfaceCapacity - integer array > 1");


#setInterfaceMacAddress
$var = '01:23:45:67:89:ab';
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceMacAddress($var), 0, "setInterfaceMacAddress - string");

$var = ['01:23:45:67:89:ab'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceMacAddress($var), 0, "setInterfaceMacAddress - array");

$var = ['01:23:45:67:89:ab', '01:23:45:67:89:ab'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setInterfaceMacAddress($var), 0, "setInterfaceMacAddress - array > 1");


#getInterfaceMacAddress 
$var = ['01:23:45:67:89:ab'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
$interface->setInterfaceMacAddress($var);
cmp_deeply($interface->getInterfaceMacAddress(), $var, "getInterfaceMacAddress - returns value");

$interface = SimpleLookupService::Records::Network::Interface->new();
cmp_deeply($interface->getInterfaceMacAddress(), undef, "getInterfaceMacAddress - returns null");


#setDNSDomains
$var = 'es.net';
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setDNSDomains($var), 0, "setDNSDomains - string");

$var = ['es.net'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setDNSDomains($var), 0, "setDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1'});
is($interface->setDNSDomains($var), 0, "setDNSDomains - array > 1");


#getDNSDomains
$var = 'es.net';
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1', domains => $var});
cmp_deeply($interface->getDNSDomains(), ['es.net'], "getDNSDomains - string");

$var = ['es.net'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1', domains => $var});
cmp_deeply($interface->getDNSDomains(), $var, "getDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$interface = SimpleLookupService::Records::Network::Interface->new();
$interface->init({interfaceName=>'wash-pt1.es.net', interfaceAddresses => '192.0.0.1', domains => $var});
cmp_deeply($interface->getDNSDomains(), $var, "getDNSDomains - array > 1");

$interface = SimpleLookupService::Records::Network::Interface->new();
cmp_deeply($interface->getDNSDomains(), undef, "getDNSDomains - returns null");