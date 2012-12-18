#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;


use SimpleLookupService::Records::Network::Host;

my $host = SimpleLookupService::Records::Network::Host->new();
my $var='';
#check record creation
ok( defined $host,            "new(record => '$host')" );

#check the class type
ok( $host->isa('SimpleLookupService::Records::Network::Host'), "class type");

#init() test
$host = SimpleLookupService::Records::Network::Host->new();
is($host->init({hostName=>'wash-pt1.es.net'}), 0, "init - basic test");


#setHostName
$var = 'albu-pt1.es.net';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setHostName($var), 0, "setHostName - string");

$var = ['albu-pt1.es.net'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setHostName($var), 0, "setHostName - array");

$var = ['albu-pt1.es.net', 'albu-pt1-mgmt.es.net'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setHostName($var), 0, "setHostName - array > 1");


$var = 'albu-pt1.es.net';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setHostName($var);
cmp_deeply($host->getHostName(), ['albu-pt1.es.net'], "getHostName - string");

$var = ['albu-pt1.es.net'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setHostName($var);
cmp_deeply($host->getHostName(), $var, "getHostName - array");

$var = ['albu-pt1.es.net', 'albu-pt1-mgmt.es.net'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setHostName($var);
cmp_deeply($host->getHostName(), $var, "getHostName - array > 1");



#setHardwareMemory
$var = '8';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setHardwareMemory($var), 0, "setHardwareMemory - string");

$var = 8;
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setHardwareMemory($var), 0, "setHardwareMemory - string");

$var = ['8'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setHardwareMemory($var), 0, "setHardwareMemory - array");

$var = ['8', '16'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setHardwareMemory($var), 0, "setHardwareMemory - array > 1");

$var = [8, 16];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setHardwareMemory($var), 0, "setHardwareMemory - array > 1");


#getHardwareMemory
$var = '8';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setHardwareMemory($var);
cmp_deeply($host->getHardwareMemory(), ['8'], "getHardwareMemory - string");

$var = ['8'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setHardwareMemory($var);
cmp_deeply($host->getHardwareMemory(), $var, "getHardwareMemory - string array");

$var = [8, 16];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setHardwareMemory($var);
cmp_deeply($host->getHardwareMemory(), $var, "getHardwareMemory - integer array > 1");

$var = ['8', '16'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setHardwareMemory($var);
cmp_deeply($host->getHardwareMemory(), $var, "getHardwareMemory - string array > 1");



#setProcessorSpeed
$var = '8';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setProcessorSpeed($var), 0, "setProcessorSpeed - string");

$var = 8;
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setProcessorSpeed($var), 0, "setProcessorSpeed - string");

$var = ['8'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setProcessorSpeed($var), 0, "setProcessorSpeed - array");

$var = ['8', '16'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setProcessorSpeed($var), 0, "setProcessorSpeed - array > 1");

$var = [8, 16];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setProcessorSpeed($var), 0, "setProcessorSpeed - array > 1");


#getProcessorSpeed
$var = '8';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setProcessorSpeed($var);
cmp_deeply($host->getProcessorSpeed(), ['8'], "getProcessorSpeed - string");

$var = ['8'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setProcessorSpeed($var);
cmp_deeply($host->getProcessorSpeed(), $var, "getProcessorSpeed - string array");

$var = [8, 16];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setProcessorSpeed($var);
cmp_deeply($host->getProcessorSpeed(), $var, "getProcessorSpeed - integer array > 1");

$var = ['8', '16'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setProcessorSpeed($var);
cmp_deeply($host->getProcessorSpeed(), $var, "getProcessorSpeed - string array > 1");


#setProcessorCount
$var = '8';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setProcessorCount($var), 0, "setProcessorCount - string");

$var = 8;
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setProcessorCount($var), 0, "setProcessorCount - string");

$var = ['8'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setProcessorCount($var), 0, "setProcessorCount - array");

$var = ['8', '16'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setProcessorCount($var), 0, "setProcessorCount - array > 1");


$var = [8, 16];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setProcessorCount($var), 0, "setProcessorCount - array > 1");

#getProcessorCount
$var = '8';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setProcessorCount($var);
cmp_deeply($host->getProcessorCount(), ['8'], "getProcessorCount - string");

$var = ['8'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setProcessorCount($var);
cmp_deeply($host->getProcessorCount(), $var, "getProcessorCount - string array");

$var = [8, 16];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setProcessorCount($var);
cmp_deeply($host->getProcessorCount(), $var, "getProcessorCount - integer array > 1");

$var = ['8', '16'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setProcessorCount($var);
cmp_deeply($host->getProcessorCount(), $var, "getProcessorCount - string array > 1");


#setProcessorCore
$var = '8';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setProcessorCore($var), 0, "setProcessorCore - string");

$var = 8;
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setProcessorCore($var), 0, "setProcessorCore - string");

$var = ['8'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setProcessorCore($var), 0, "setProcessorCore - array");

$var = ['8', '16'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setProcessorCore($var), 0, "setProcessorCore - array > 1");


$var = [8, 16];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setProcessorCore($var), 0, "setProcessorCore - array > 1");

#getProcessorCore
$var = '8';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setProcessorCore($var);
cmp_deeply($host->getProcessorCore(), ['8'], "getProcessorCore - string");

$var = ['8'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setProcessorCore($var);
cmp_deeply($host->getProcessorCore(), $var, "getProcessorCore - string array");

$var = [8, 16];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setProcessorCore($var);
cmp_deeply($host->getProcessorCore(), $var, "getProcessorCore - integer array > 1");

$var = ['8', '16'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setProcessorCore($var);
cmp_deeply($host->getProcessorCore(), $var, "getProcessorCore - string array > 1");

#setOSName
$var = 'CentOS 5';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setOSName($var), 0, "setOSName - string");

$var = ['CentOS 5'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setOSName($var), 0, "setOSName - array");

$var = ['CentOS 5', 'CentOS 6'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setOSName($var), 0, "setOSName - array > 1");


#getOSName
$var = 'CentOS 5';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setOSName($var);
cmp_deeply($host->getOSName(), ['CentOS 5'], "getOSName - string");

$var = ['CentOS 5'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setOSName($var);
cmp_deeply($host->getOSName(), $var, "getOSName - array");

$var = ['CentOS 5', 'CentOS 6'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setOSName($var);
cmp_deeply($host->getOSName(), $var, "getOSName - array > 1");


#setOSVersion
$var = '5';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setOSVersion($var), 0, "setOSVersion - string");

$var = ['5.6'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setOSVersion($var), 0, "setOSVersion - array");

$var = ['5.5', '5.6'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setOSVersion($var), 0, "setOSVersion - array > 1");


#getOSVersion
$var = '5';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setOSVersion($var);
cmp_deeply($host->getOSVersion(), ['5'], "getOSVersion - string");

$var = ['5'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setOSVersion($var);
cmp_deeply($host->getOSVersion(), $var, "getOSVersion - array");

$var = ['5', '6'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setOSVersion($var);
cmp_deeply($host->getOSVersion(), $var, "getOSVersion - array > 1");


#setOSKernel
$var = '2.6.38.198.1';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setOSKernel($var), 0, "setOSKernel - string");

$var = ['2.6.38.198.1'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setOSKernel($var), 0, "setOSKernel - array");

$var = ['2.6.38.198.1', '2.6.38.198.2'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setOSKernel($var), 0, "setOSKernel - array > 1");

#getOSKernel
$var = '2.6.38.198.1';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setOSKernel($var);
cmp_deeply($host->getOSKernel(), ['2.6.38.198.1'], "getOSKernel - string");

$var = ['2.6.38.198.1'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setOSKernel($var);
cmp_deeply($host->getOSKernel(), $var, "getOSKernel - array");

$var = ['2.6.38.198.1', '2.6.38.198.2'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setOSKernel($var);
cmp_deeply($host->getOSKernel(), $var, "getOSKernel - array > 1");



#setInterfaces
$var = 'http://localhost:8080/lookup/interface/abcd-e45-5466777';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setInterfaces($var), 0, "setInterfaces - string");


$var = ['http://localhost:8080/lookup/interface/abcd-e45-5466777'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setInterfaces($var), 0, "setInterfaces - array");

$var = ['http://localhost:8080/lookup/interface/abcd-e45-5466777', 'http://localhost:8080/lookup/interface/abcd-e45-54667876'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setInterfaces($var), 0, "setInterfaces - array > 1");



#getInterfaces
$var = 'http://localhost:8080/lookup/interface/abcd-e45-5466777';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setInterfaces($var);
cmp_deeply($host->getInterfaces(), ['http://localhost:8080/lookup/interface/abcd-e45-5466777'], "getHostAdministrators - string");

$var = ['http://localhost:8080/lookup/interface/abcd-e45-5466777'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setInterfaces($var);
cmp_deeply($host->getInterfaces(), $var, "getInterfaces - array");

$var = ['http://localhost:8080/lookup/interface/abcd-e45-5466777', 'http://localhost:8080/lookup/interface/abcd-e45-5466876'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setInterfaces($var);
cmp_deeply($host->getInterfaces(), $var, "getInterfaces - array > 1");

$host = SimpleLookupService::Records::Network::Host->new();
cmp_deeply($host->getInterfaces(), undef, "getInterfaces - returns null");




#setTcpCongestionAlgorithm
$var = 'cubic';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setTcpCongestionAlgorithm($var), 0, "setTcpCongestionAlgorithm - string");

$var = ['cubic'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setTcpCongestionAlgorithm($var), 0, "setTcpCongestionAlgorithm - array");

$var = ['cubic', 'reno'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setTcpCongestionAlgorithm($var), 0, "setTcpCongestionAlgorithm - array > 1");

#getTcpCongestionAlgorithm
$var = 'cubic';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setTcpCongestionAlgorithm($var);
cmp_deeply($host->getTcpCongestionAlgorithm(), ['cubic'], "getTcpCongestionAlgorithm - string");

$var = ['cubic'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setTcpCongestionAlgorithm($var);
cmp_deeply($host->getTcpCongestionAlgorithm(), $var, "getTcpCongestionAlgorithm - array");

$var = ['cubic', 'reno'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setTcpCongestionAlgorithm($var);
cmp_deeply($host->getTcpCongestionAlgorithm(), $var, "getTcpCongestionAlgorithm - array > 1");


#setTcpMaxBuffer
$var = '1024';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setTcpMaxBuffer($var), 0, "setTcpMaxBuffer - string");

$var = 1024;
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setTcpMaxBuffer($var), 0, "setTcpMaxBuffer - integer");

$var = ['1024'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setTcpMaxBuffer($var), 0, "setTcpMaxBuffer - array");

$var = [1024];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setTcpMaxBuffer($var), 0, "setTcpMaxBuffer - integer array");

$var = ['512', '1024'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setTcpMaxBuffer($var), 0, "setTcpMaxBuffer - array > 1");

$var = [512, 1024];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setTcpMaxBuffer($var), 0, "setTcpMaxBuffer - integer array > 1");


#getTcpMaxBuffer
$var = '1024';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setTcpMaxBuffer($var);
cmp_deeply($host->getTcpMaxBuffer(), ['1024'], "getTcpMaxBuffer -  string val");

$var = 1024;
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setTcpMaxBuffer($var);
cmp_deeply($host->getTcpMaxBuffer(), [1024], "getTcpMaxBuffer - integer val");

$var = ['1024'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setTcpMaxBuffer($var);
cmp_deeply($host->getTcpMaxBuffer(), $var, "getTcpMaxBuffer - string array");

$var = [1024];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setTcpMaxBuffer($var);
cmp_deeply($host->getTcpMaxBuffer(), $var, "getTcpMaxBuffer - integer array");

$var = ['512', '1024'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setTcpMaxBuffer($var);
cmp_deeply($host->getTcpMaxBuffer(), $var, "getTcpMaxBuffer - string array > 1");

$var = [512, 1024];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setTcpMaxBuffer($var);
cmp_deeply($host->getTcpMaxBuffer(), $var, "getTcpMaxBuffer - integer array > 1");


#setTcpAutotuneMaxBuffer
$var = '1024';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setTcpAutotuneMaxBuffer($var), 0, "setTcpAutotuneMaxBuffer - string");

$var = 1024;
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setTcpAutotuneMaxBuffer($var), 0, "setTcpAutotuneMaxBuffer - integer");

$var = ['1024'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setTcpAutotuneMaxBuffer($var), 0, "setTcpAutotuneMaxBuffer - array");

$var = [1024];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setTcpAutotuneMaxBuffer($var), 0, "setTcpAutotuneMaxBuffer - integer array");

$var = ['512', '1024'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setTcpAutotuneMaxBuffer($var), 0, "setTcpAutotuneMaxBuffer - array > 1");

$var = [512, 1024];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setTcpAutotuneMaxBuffer($var), 0, "setTcpAutotuneMaxBuffer - integer array > 1");


#getTcpAutotuneMaxBuffer
$var = '1024';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setTcpAutotuneMaxBuffer($var);
cmp_deeply($host->getTcpAutotuneMaxBuffer(), ['1024'], "getTcpAutotuneMaxBuffer -  string val");

$var = 1024;
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setTcpAutotuneMaxBuffer($var);
cmp_deeply($host->getTcpAutotuneMaxBuffer(), [1024], "getTcpAutotuneMaxBuffer - integer val");

$var = ['1024'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setTcpAutotuneMaxBuffer($var);
cmp_deeply($host->getTcpAutotuneMaxBuffer(), $var, "getTcpAutotuneMaxBuffer - string array");

$var = [1024];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setTcpAutotuneMaxBuffer($var);
cmp_deeply($host->getTcpAutotuneMaxBuffer(), $var, "getTcpAutotuneMaxBuffer - integer array");

$var = ['512', '1024'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setTcpAutotuneMaxBuffer($var);
cmp_deeply($host->getTcpAutotuneMaxBuffer(), $var, "getTcpAutotuneMaxBuffer - string array > 1");

$var = [512, 1024];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setTcpAutotuneMaxBuffer($var);
cmp_deeply($host->getTcpAutotuneMaxBuffer(), $var, "getTcpAutotuneMaxBuffer - integer array > 1");


#setHostAdministrators
$var = 'http://localhost:8080/lookup/person/abcd-e45-5466777';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setHostAdministrators($var), 0, "setHostAdministrators - string");


$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setHostAdministrators($var), 0, "setHostAdministrators - array");

$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777', 'http://localhost:8080/lookup/person/abcd-e45-54667876'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setHostAdministrators($var), 0, "setHostAdministrators - array > 1");


#getHostAdministrators
$var = 'http://localhost:8080/lookup/person/abcd-e45-5466777';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setHostAdministrators($var);
cmp_deeply($host->getHostAdministrators(), ['http://localhost:8080/lookup/person/abcd-e45-5466777'], "getHostAdministrators - string");

$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setHostAdministrators($var);
cmp_deeply($host->getHostAdministrators(), $var, "getHostAdministrators - array");

$var = ['http://localhost:8080/lookup/person/abcd-e45-5466777', 'http://localhost:8080/lookup/person/abcd-e45-5466876'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
$host->setHostAdministrators($var);
cmp_deeply($host->getHostAdministrators(), $var, "getHostAdministrators - array > 1");

$host = SimpleLookupService::Records::Network::Host->new();
cmp_deeply($host->getHostAdministrators(), undef, "getHostAdministrators - returns null");



#setDNSDomains
$var = 'es.net';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setDNSDomains($var), 0, "setDNSDomains - string");

$var = ['es.net'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setDNSDomains($var), 0, "setDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setDNSDomains($var), 0, "setDNSDomains - array > 1");


#getDNSDomains
$var = 'es.net';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net', domains => $var});
cmp_deeply($host->getDNSDomains(), ['es.net'], "getDNSDomains - string");

$var = ['es.net'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net', domains => $var});
cmp_deeply($host->getDNSDomains(), $var, "getDNSDomains - array");

$var = ['es.net', 'lbl.gov'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net', domains => $var});
cmp_deeply($host->getDNSDomains(), $var, "getDNSDomains - array > 1");

$host = SimpleLookupService::Records::Network::Host->new();
cmp_deeply($host->getDNSDomains(), undef, "getDNSDomains - returns null");



#setSiteName
$var = 'LBL';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setSiteName($var), 0, "setSiteName - string");

$var = ['LBL'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setSiteName($var), 0, "setSiteName - array");

$var = ['LBL', 'LBNL'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setSiteName($var), -1, "setSiteName - array > 1");

#getSiteName
$var = 'LBL';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net' , siteName => $var});
cmp_deeply($host->getSiteName(), ['LBL'], "getSiteName - string");

$var = ['LBL'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net', siteName => $var});
cmp_deeply($host->getSiteName(), $var, "getSiteName - array");

$host = SimpleLookupService::Records::Network::Host->new();
cmp_deeply($host->getSiteName(), undef, "getSiteName - returns null");


#setCity
$var = 'Berkeley';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setCity($var), 0, "setCity - string");

$var = ['Berkeley'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setCity($var), 0, "setCity - array");

$var = ['Berkeley', 'LBNL'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setCity($var), -1, "setCity - array > 1");

#getCity
$var = 'Berkeley';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net', city => $var});
cmp_deeply($host->getCity(), ['Berkeley'], "getCity - string");

$var = ['Berkeley'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net', city => $var});
cmp_deeply($host->getCity(), $var, "getCity - array");

$host = SimpleLookupService::Records::Network::Host->new();
cmp_deeply($host->getCity(), undef, "getCity - returns null");


#setRegion
$var = 'CA';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setRegion($var), 0, "setRegion - string");

$var = ['CA'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setRegion($var), 0, "setRegion - array");

$var = ['CA', 'WA'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setRegion($var), -1, "setRegion - array > 1");


#getRegion
$var = 'CA';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net', region => $var});
cmp_deeply($host->getRegion(), ['CA'], "getRegion - string");

$var = ['CA'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net', region => $var});
cmp_deeply($host->getRegion(), $var, "getRegion - array");

$host = SimpleLookupService::Records::Network::Host->new();
cmp_deeply($host->getRegion(), undef, "getRegion - returns null");


#setCountry
$var = 'US';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setCountry($var), 0, "setCountry - string");

$var = ['US'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setCountry($var), 0, "setCountry - array");

$var = 'USA';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setCountry($var), -1, "setCountry - not a 2 digit code");

$var = ['USA'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setCountry($var), -1, "setCountry - not a 2 digit code");


$var = ['US', 'UK'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setCountry($var), -1, "setCountry - array > 1");

#getCountry
$var = 'US';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net', country => $var});
cmp_deeply($host->getCountry(), ['US'], "getCountry - string");

$var = ['US'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net',  country => $var});
cmp_deeply($host->getCountry(), $var, "getCountry - array");

$host = SimpleLookupService::Records::Network::Host->new();
cmp_deeply($host->getCountry(), undef, "getCountry - returns null");


#setZipCode
$var = '94720';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setZipCode($var), 0, "setZipCode - string");

$var = ['94720'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setZipCode($var), 0, "setZipCode - array");

$var = ['94720', '94724'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setZipCode($var), -1, "setZipCode - array > 1");


#getZipCode
$var = '94720';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net', zipCode => $var});
cmp_deeply($host->getZipCode(), ['94720'], "getZipCode - string");

$var = ['94720'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net', zipCode => $var});
cmp_deeply($host->getZipCode(), $var, "getZipCode - array");

$host = SimpleLookupService::Records::Network::Host->new();
cmp_deeply($host->getZipCode(), undef, "getZipCode - returns null");


#setLatitude
$var = '-18';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setLatitude($var), 0, "setLatitude - string");

$var = ['18'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setLatitude($var), 0, "setLatitude - array");

$var = ['95'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setLatitude($var), -1, "setLatitude - not within range");

$var = ['18', '28'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setLatitude($var), -1, "setLatitude - array > 1");

#getLatitude
$var = '-18';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net', latitude => $var});
cmp_deeply($host->getLatitude(), ['-18'], "getLatitude - string");

$var = ['-18'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net', latitude => $var});
cmp_deeply($host->getLatitude(), $var, "getLatitude - array");

$host = SimpleLookupService::Records::Network::Host->new();
cmp_deeply($host->getLatitude(), undef, "getLatitude - returns null");

#setLongitude
$var = '-18';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setLongitude($var), 0, "setLongitude - string");

$var = ['18'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setLongitude($var), 0, "setLongitude - array");

$var = ['187'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setLongitude($var), -1, "setLongitude - not within range");

$var = ['18', '28'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net'});
is($host->setLongitude($var), -1, "setLongitude - array > 1");

#getLongitude
$var = '-18';
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net', longitude => $var});
cmp_deeply($host->getLongitude(), ['-18'], "getLongitude - string");

$var = ['-18'];
$host = SimpleLookupService::Records::Network::Host->new();
$host->init({hostName=>'wash-pt1.es.net', longitude => $var});
cmp_deeply($host->getLongitude(), $var, "getLongitude - array");

$host = SimpleLookupService::Records::Network::Host->new();
cmp_deeply($host->getLongitude(), undef, "getLongitude - returns null");