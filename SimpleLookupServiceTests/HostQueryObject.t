#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;

use SimpleLookupService::QueryObjects::Network::HostQueryObject;

my $query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();

#check record creation
ok( defined $query,            "new(query => '$query')" );

#check the class type
ok( $query->isa('SimpleLookupService::QueryObjects::Network::HostQueryObject'), "and it's the right class");

#init() test
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
is($query->init(), 0, "init - no parameters");


#setHostName
my $var = 'albu-pt1.es.net';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setHostName($var), 0, "setHostName - string");

$var = ['albu-pt1.es.net'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setHostName($var), 0, "setHostName - array");

$var = ['albu-pt1.es.net', 'albu-pt1-mgmt.es.net'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setHostName($var), 0, "setHostName - array > 1");


$var = 'albu-pt1.es.net';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setHostName($var);
cmp_deeply($query->getHostName(), ['albu-pt1.es.net'], "getHostName - string");

$var = ['albu-pt1.es.net'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setHostName($var);
cmp_deeply($query->getHostName(), $var, "getHostName - array");

$var = ['albu-pt1.es.net', 'albu-pt1-mgmt.es.net'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setHostName($var);
cmp_deeply($query->getHostName(), $var, "getHostName - array > 1");



#setHardwareMemory
$var = '8';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setHardwareMemory($var), 0, "setHardwareMemory - string");

$var = 8;
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setHardwareMemory($var), 0, "setHardwareMemory - string");

$var = ['8'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setHardwareMemory($var), 0, "setHardwareMemory - array");

$var = ['8', '16'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setHardwareMemory($var), 0, "setHardwareMemory - array > 1");

$var = [8, 16];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setHardwareMemory($var), 0, "setHardwareMemory - array > 1");


#getHardwareMemory
$var = '8';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setHardwareMemory($var);
cmp_deeply($query->getHardwareMemory(), ['8'], "getHardwareMemory - string");

$var = ['8'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setHardwareMemory($var);
cmp_deeply($query->getHardwareMemory(), $var, "getHardwareMemory - string array");

$var = [8, 16];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setHardwareMemory($var);
cmp_deeply($query->getHardwareMemory(), $var, "getHardwareMemory - integer array > 1");

$var = ['8', '16'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setHardwareMemory($var);
cmp_deeply($query->getHardwareMemory(), $var, "getHardwareMemory - string array > 1");



#setProcessorSpeed
$var = '8';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setProcessorSpeed($var), 0, "setProcessorSpeed - string");

$var = 8;
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setProcessorSpeed($var), 0, "setProcessorSpeed - string");

$var = ['8'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setProcessorSpeed($var), 0, "setProcessorSpeed - array");

$var = ['8', '16'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setProcessorSpeed($var), 0, "setProcessorSpeed - array > 1");

$var = [8, 16];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setProcessorSpeed($var), 0, "setProcessorSpeed - array > 1");


#getProcessorSpeed
$var = '8';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setProcessorSpeed($var);
cmp_deeply($query->getProcessorSpeed(), ['8'], "getProcessorSpeed - string");

$var = ['8'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setProcessorSpeed($var);
cmp_deeply($query->getProcessorSpeed(), $var, "getProcessorSpeed - string array");

$var = [8, 16];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setProcessorSpeed($var);
cmp_deeply($query->getProcessorSpeed(), $var, "getProcessorSpeed - integer array > 1");

$var = ['8', '16'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setProcessorSpeed($var);
cmp_deeply($query->getProcessorSpeed(), $var, "getProcessorSpeed - string array > 1");


#setProcessorCount
$var = '8';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setProcessorCount($var), 0, "setProcessorCount - string");

$var = 8;
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setProcessorCount($var), 0, "setProcessorCount - string");

$var = ['8'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setProcessorCount($var), 0, "setProcessorCount - array");

$var = ['8', '16'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setProcessorCount($var), 0, "setProcessorCount - array > 1");


$var = [8, 16];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setProcessorCount($var), 0, "setProcessorCount - array > 1");

#getProcessorCount
$var = '8';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setProcessorCount($var);
cmp_deeply($query->getProcessorCount(), ['8'], "getProcessorCount - string");

$var = ['8'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setProcessorCount($var);
cmp_deeply($query->getProcessorCount(), $var, "getProcessorCount - string array");

$var = [8, 16];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setProcessorCount($var);
cmp_deeply($query->getProcessorCount(), $var, "getProcessorCount - integer array > 1");

$var = ['8', '16'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setProcessorCount($var);
cmp_deeply($query->getProcessorCount(), $var, "getProcessorCount - string array > 1");


#setProcessorCore
$var = '8';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setProcessorCore($var), 0, "setProcessorCore - string");

$var = 8;
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setProcessorCore($var), 0, "setProcessorCore - string");

$var = ['8'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setProcessorCore($var), 0, "setProcessorCore - array");

$var = ['8', '16'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setProcessorCore($var), 0, "setProcessorCore - array > 1");


$var = [8, 16];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setProcessorCore($var), 0, "setProcessorCore - array > 1");

#getProcessorCore
$var = '8';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setProcessorCore($var);
cmp_deeply($query->getProcessorCore(), ['8'], "getProcessorCore - string");

$var = ['8'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setProcessorCore($var);
cmp_deeply($query->getProcessorCore(), $var, "getProcessorCore - string array");

$var = [8, 16];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setProcessorCore($var);
cmp_deeply($query->getProcessorCore(), $var, "getProcessorCore - integer array > 1");

$var = ['8', '16'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setProcessorCore($var);
cmp_deeply($query->getProcessorCore(), $var, "getProcessorCore - string array > 1");

#setOSName
$var = 'CentOS 5';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setOSName($var), 0, "setOSName - string");

$var = ['CentOS 5'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setOSName($var), 0, "setOSName - array");

$var = ['CentOS 5', 'CentOS 6'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setOSName($var), 0, "setOSName - array > 1");


#getOSName
$var = 'CentOS 5';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setOSName($var);
cmp_deeply($query->getOSName(), ['CentOS 5'], "getOSName - string");

$var = ['CentOS 5'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setOSName($var);
cmp_deeply($query->getOSName(), $var, "getOSName - array");

$var = ['CentOS 5', 'CentOS 6'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setOSName($var);
cmp_deeply($query->getOSName(), $var, "getOSName - array > 1");


#setOSVersion
$var = '5';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setOSVersion($var), 0, "setOSVersion - string");

$var = ['5.6'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setOSVersion($var), 0, "setOSVersion - array");

$var = ['5.5', '5.6'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setOSVersion($var), 0, "setOSVersion - array > 1");


#getOSVersion
$var = '5';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setOSVersion($var);
cmp_deeply($query->getOSVersion(), ['5'], "getOSVersion - string");

$var = ['5'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setOSVersion($var);
cmp_deeply($query->getOSVersion(), $var, "getOSVersion - array");

$var = ['5', '6'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setOSVersion($var);
cmp_deeply($query->getOSVersion(), $var, "getOSVersion - array > 1");


#setOSKernel
$var = '2.6.38.198.1';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setOSKernel($var), 0, "setOSKernel - string");

$var = ['2.6.38.198.1'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setOSKernel($var), 0, "setOSKernel - array");

$var = ['2.6.38.198.1', '2.6.38.198.2'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setOSKernel($var), 0, "setOSKernel - array > 1");

#getOSKernel
$var = '2.6.38.198.1';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setOSKernel($var);
cmp_deeply($query->getOSKernel(), ['2.6.38.198.1'], "getOSKernel - string");

$var = ['2.6.38.198.1'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setOSKernel($var);
cmp_deeply($query->getOSKernel(), $var, "getOSKernel - array");

$var = ['2.6.38.198.1', '2.6.38.198.2'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setOSKernel($var);
cmp_deeply($query->getOSKernel(), $var, "getOSKernel - array > 1");



#setInterfaces
$var = 'http://localhost:8080/lookup/interface/abcd-e45-5466777';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setInterfaces($var), 0, "setInterfaces - string");


$var = ['http://localhost:8080/lookup/interface/abcd-e45-5466777'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setInterfaces($var), 0, "setInterfaces - array");

$var = ['http://localhost:8080/lookup/interface/abcd-e45-5466777', 'http://localhost:8080/lookup/interface/abcd-e45-54667876'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setInterfaces($var), 0, "setInterfaces - array > 1");



#getInterfaces
$var = 'http://localhost:8080/lookup/interface/abcd-e45-5466777';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setInterfaces($var);
cmp_deeply($query->getInterfaces(), ['http://localhost:8080/lookup/interface/abcd-e45-5466777'], "getHostAdministrators - string");

$var = ['http://localhost:8080/lookup/interface/abcd-e45-5466777'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setInterfaces($var);
cmp_deeply($query->getInterfaces(), $var, "getInterfaces - array");

$var = ['http://localhost:8080/lookup/interface/abcd-e45-5466777', 'http://localhost:8080/lookup/interface/abcd-e45-5466876'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setInterfaces($var);
cmp_deeply($query->getInterfaces(), $var, "getInterfaces - array > 1");

$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
cmp_deeply($query->getInterfaces(), undef, "getInterfaces - returns null");




#setTcpCongestionAlgorithm
$var = 'cubic';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setTcpCongestionAlgorithm($var), 0, "setTcpCongestionAlgorithm - string");

$var = ['cubic'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setTcpCongestionAlgorithm($var), 0, "setTcpCongestionAlgorithm - array");

$var = ['cubic', 'reno'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setTcpCongestionAlgorithm($var), 0, "setTcpCongestionAlgorithm - array > 1");

#getTcpCongestionAlgorithm
$var = 'cubic';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setTcpCongestionAlgorithm($var);
cmp_deeply($query->getTcpCongestionAlgorithm(), ['cubic'], "getTcpCongestionAlgorithm - string");

$var = ['cubic'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setTcpCongestionAlgorithm($var);
cmp_deeply($query->getTcpCongestionAlgorithm(), $var, "getTcpCongestionAlgorithm - array");

$var = ['cubic', 'reno'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setTcpCongestionAlgorithm($var);
cmp_deeply($query->getTcpCongestionAlgorithm(), $var, "getTcpCongestionAlgorithm - array > 1");


#setTcpMaxBuffer
$var = '1024';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setTcpMaxBuffer($var), 0, "setTcpMaxBuffer - string");

$var = 1024;
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setTcpMaxBuffer($var), 0, "setTcpMaxBuffer - integer");

$var = ['1024'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setTcpMaxBuffer($var), 0, "setTcpMaxBuffer - array");

$var = [1024];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setTcpMaxBuffer($var), 0, "setTcpMaxBuffer - integer array");

$var = ['512', '1024'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setTcpMaxBuffer($var), 0, "setTcpMaxBuffer - array > 1");

$var = [512, 1024];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setTcpMaxBuffer($var), 0, "setTcpMaxBuffer - integer array > 1");


#getTcpMaxBuffer
$var = '1024';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setTcpMaxBuffer($var);
cmp_deeply($query->getTcpMaxBuffer(), ['1024'], "getTcpMaxBuffer -  string val");

$var = 1024;
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setTcpMaxBuffer($var);
cmp_deeply($query->getTcpMaxBuffer(), [1024], "getTcpMaxBuffer - integer val");

$var = ['1024'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setTcpMaxBuffer($var);
cmp_deeply($query->getTcpMaxBuffer(), $var, "getTcpMaxBuffer - string array");

$var = [1024];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setTcpMaxBuffer($var);
cmp_deeply($query->getTcpMaxBuffer(), $var, "getTcpMaxBuffer - integer array");

$var = ['512', '1024'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setTcpMaxBuffer($var);
cmp_deeply($query->getTcpMaxBuffer(), $var, "getTcpMaxBuffer - string array > 1");

$var = [512, 1024];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setTcpMaxBuffer($var);
cmp_deeply($query->getTcpMaxBuffer(), $var, "getTcpMaxBuffer - integer array > 1");


#setTcpAutotuneMaxBuffer
$var = '1024';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setTcpAutotuneMaxBuffer($var), 0, "setTcpAutotuneMaxBuffer - string");

$var = 1024;
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setTcpAutotuneMaxBuffer($var), 0, "setTcpAutotuneMaxBuffer - integer");

$var = ['1024'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setTcpAutotuneMaxBuffer($var), 0, "setTcpAutotuneMaxBuffer - array");

$var = [1024];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setTcpAutotuneMaxBuffer($var), 0, "setTcpAutotuneMaxBuffer - integer array");

$var = ['512', '1024'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setTcpAutotuneMaxBuffer($var), 0, "setTcpAutotuneMaxBuffer - array > 1");

$var = [512, 1024];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setTcpAutotuneMaxBuffer($var), 0, "setTcpAutotuneMaxBuffer - integer array > 1");


#getTcpAutotuneMaxBuffer
$var = '1024';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setTcpAutotuneMaxBuffer($var);
cmp_deeply($query->getTcpAutotuneMaxBuffer(), ['1024'], "getTcpAutotuneMaxBuffer -  string val");

$var = 1024;
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setTcpAutotuneMaxBuffer($var);
cmp_deeply($query->getTcpAutotuneMaxBuffer(), [1024], "getTcpAutotuneMaxBuffer - integer val");

$var = ['1024'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setTcpAutotuneMaxBuffer($var);
cmp_deeply($query->getTcpAutotuneMaxBuffer(), $var, "getTcpAutotuneMaxBuffer - string array");

$var = [1024];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setTcpAutotuneMaxBuffer($var);
cmp_deeply($query->getTcpAutotuneMaxBuffer(), $var, "getTcpAutotuneMaxBuffer - integer array");

$var = ['512', '1024'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setTcpAutotuneMaxBuffer($var);
cmp_deeply($query->getTcpAutotuneMaxBuffer(), $var, "getTcpAutotuneMaxBuffer - string array > 1");

$var = [512, 1024];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setTcpAutotuneMaxBuffer($var);
cmp_deeply($query->getTcpAutotuneMaxBuffer(), $var, "getTcpAutotuneMaxBuffer - integer array > 1");


#setHostAdministrators
$var = 'http://localhost:8080/lookup/person/abcd-e45-5466777';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setHostAdministrators($var), 0, "setHostAdministrators - string");


$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setHostAdministrators($var), 0, "setHostAdministrators - array");

$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777', 'http://localhost:8080/lookup/person/abcd-e45-54667876'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setHostAdministrators($var), 0, "setHostAdministrators - array > 1");


#getHostAdministrators
$var = 'http://localhost:8080/lookup/person/abcd-e45-5466777';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setHostAdministrators($var);
cmp_deeply($query->getHostAdministrators(), ['http://localhost:8080/lookup/person/abcd-e45-5466777'], "getHostAdministrators - string");

$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setHostAdministrators($var);
cmp_deeply($query->getHostAdministrators(), $var, "getHostAdministrators - array");

$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777', 'http://localhost:8080/lookup/person/abcd-e45-5466876'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setHostAdministrators($var);
cmp_deeply($query->getHostAdministrators(), $var, "getHostAdministrators - array > 1");

$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
cmp_deeply($query->getHostAdministrators(), undef, "getHostAdministrators - returns null");



#setDNSDomains
$var = 'es.net';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setDNSDomains($var), 0, "setDNSDomains - string");

$var = ['es.net'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setDNSDomains($var), 0, "setDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setDNSDomains($var), 0, "setDNSDomains - array > 1");


#getDNSDomains
$var = 'es.net';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setDNSDomains($var);
cmp_deeply($query->getDNSDomains(), ['es.net'], "getDNSDomains - string");

$var = ['es.net'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setDNSDomains($var);
cmp_deeply($query->getDNSDomains(), $var, "getDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setDNSDomains($var);
cmp_deeply($query->getDNSDomains(), $var, "getDNSDomains - array > 1");

$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
cmp_deeply($query->getDNSDomains(), undef, "getDNSDomains - returns null");



#setSiteName
$var = 'LBL';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setSiteName($var), 0, "setSiteName - string");

$var = ['LBL'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setSiteName($var), 0, "setSiteName - array");

$var = ['LBL', 'LBNL'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setSiteName($var), 0, "setSiteName - array > 1");

#getSiteName
$var = 'LBL';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setSiteName($var);
cmp_deeply($query->getSiteName(), ['LBL'], "getSiteName - string");

$var = ['LBL'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setSiteName($var);
cmp_deeply($query->getSiteName(), $var, "getSiteName - array");

$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
cmp_deeply($query->getSiteName(), undef, "getSiteName - returns null");


#setCity
$var = 'Berkeley';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setCity($var), 0, "setCity - string");

$var = ['Berkeley'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setCity($var), 0, "setCity - array");

$var = ['Berkeley', 'LBNL'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setCity($var), 0, "setCity - array > 1");

#getCity
$var = 'Berkeley';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setCity($var);
cmp_deeply($query->getCity(), ['Berkeley'], "getCity - string");

$var = ['Berkeley'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setCity($var);
cmp_deeply($query->getCity(), $var, "getCity - array");

$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
cmp_deeply($query->getCity(), undef, "getCity - returns null");


#setRegion
$var = 'CA';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setRegion($var), 0, "setRegion - string");

$var = ['CA'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setRegion($var), 0, "setRegion - array");

$var = ['CA', 'WA'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setRegion($var), 0, "setRegion - array > 1");


#getRegion
$var = 'CA';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setRegion($var);
cmp_deeply($query->getRegion(), ['CA'], "getRegion - string");

$var = ['CA'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setRegion($var);
cmp_deeply($query->getRegion(), $var, "getRegion - array");

$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
cmp_deeply($query->getRegion(), undef, "getRegion - returns null");


#setCountry
$var = 'US';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setCountry($var), 0, "setCountry - string");

$var = ['US'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setCountry($var), 0, "setCountry - array");

$var = 'USA';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setCountry($var), 0, "setCountry - not a 2 digit code");

$var = ['USA'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setCountry($var), 0, "setCountry - not a 2 digit code");


$var = ['US', 'UK'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setCountry($var), 0, "setCountry - array > 1");

#getCountry
$var = 'US';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setCountry($var);
cmp_deeply($query->getCountry(), ['US'], "getCountry - string");

$var = ['US'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setCountry($var);
cmp_deeply($query->getCountry(), $var, "getCountry - array");

$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
cmp_deeply($query->getCountry(), undef, "getCountry - returns null");


#setZipCode
$var = '94720';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setZipCode($var), 0, "setZipCode - string");

$var = ['94720'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setZipCode($var), 0, "setZipCode - array");

$var = ['94720', '94724'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setZipCode($var), 0, "setZipCode - array > 1");


#getZipCode
$var = '94720';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setZipCode($var);
cmp_deeply($query->getZipCode(), ['94720'], "getZipCode - string");

$var = ['94720'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setZipCode($var);
cmp_deeply($query->getZipCode(), $var, "getZipCode - array");

$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
cmp_deeply($query->getZipCode(), undef, "getZipCode - returns null");


#setLatitude
$var = '-18';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setLatitude($var), 0, "setLatitude - string");

$var = ['18'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setLatitude($var), 0, "setLatitude - array");

$var = ['95'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setLatitude($var), 0, "setLatitude - not within range");

$var = ['18', '28'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setLatitude($var), 0, "setLatitude - array > 1");

#getLatitude
$var = '-18';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setLatitude($var);
cmp_deeply($query->getLatitude(), ['-18'], "getLatitude - string");

$var = ['-18'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setLatitude($var);
cmp_deeply($query->getLatitude(), $var, "getLatitude - array");

$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
cmp_deeply($query->getLatitude(), undef, "getLatitude - returns null");

#setLongitude
$var = '-18';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setLongitude($var), 0, "setLongitude - string");

$var = ['18'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setLongitude($var), 0, "setLongitude - array");

$var = ['187'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setLongitude($var), 0, "setLongitude - not within range");

$var = ['18', '28'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
is($query->setLongitude($var), 0, "setLongitude - array > 1");

#getLongitude
$var = '-18';
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setLongitude($var);
cmp_deeply($query->getLongitude(), ['-18'], "getLongitude - string");

$var = ['-18'];
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setLongitude($var);
cmp_deeply($query->getLongitude(), $var, "getLongitude - array");

$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
cmp_deeply($query->getLongitude(), undef, "getLongitude - returns null");



#toURLParameters - multiple values
#this test may result in error -  if so check manually
$query = SimpleLookupService::QueryObjects::Network::HostQueryObject->new();
$query->init();
$query->setOperator('all');
$query->setRecordTtlInMinutes('60');
$query->setLongitude($var);
$query->setTcpMaxBuffer(1024);
is($query->toURLParameters(),'?operator=all&ttl=60&location-longitude=-18&type=host&host-net-tcp-maxbuffer=1024',"toURLParameters - parameters as array");