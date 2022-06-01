use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;


use SimpleLookupService::Records::Security::Signature;

my $signature = SimpleLookupService::Records::Security::Signature->new();
my $var ='';
#check record creation
ok( defined $signature,            "new(record => '$signature')" );

#check the class type
ok( $signature->isa('SimpleLookupService::Records::Security::Signature'), "class type");

#init() test
$signature = SimpleLookupService::Records::Security::Signature->new();
is($signature->init({x509certificate=>'http://somehost/certificate'}), 0, "init - basic test");


#setPersonName
$var = ['http://somehost/different/certificate'];
$signature = SimpleLookupService::Records::Security::Signature->new();
$signature->init({x509certificate=>'http://somehost/certificate'});
is($signature->setCertificate($var), 0, "setCertificate - string");

cmp_deeply($signature->getCertificate(), $var, "getCertificate - array of 1");


my $digest = ["sha256"];
cmp_deeply($signature->getDigest, $digest, "getDigest - array of 1");


my $encoding = ["base64"];
cmp_deeply($signature->getSignatureEncoding, $encoding, "getSignatureEncoding - array of 1");