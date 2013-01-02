#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;

use SimpleLookupService::QueryObjects::QueryObject;

my $query = SimpleLookupService::QueryObjects::QueryObject->new();

#check record creation
ok( defined $query,            "new(query => '$query')" );

#check the class type
ok( $query->isa('SimpleLookupService::QueryObjects::QueryObject'), "and it's the right class");

#init() tests
#check init() - no parameters
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->init(), 0, "init - no parameters");

#init() -with parameters
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->init(type=>'sometype', expires=>'2012-12-17T10:14:03.208Z', ttl=>'PT60M', uri=>'lookup/service/aadbce-12345-adf34'), 0, "init - with parameters");


#setRecordType tests
#setRecordType() - pass array
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->setRecordType(['sometype1']), 0,"setRecordType() - pass array");

#setRecordType() - pass string - converts to array
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->setRecordType('sometype2'), 0, "setRecordType() - pass string - converts to array");

#setRecordType() - pass array with size >1
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->setRecordType(['sometype4','sometype3']), 0, "setRecordType() - pass array with size >1");


#getRecordType
#getRecordType test
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->setRecordType(['sometype']);
cmp_deeply( $query->getRecordType(), ['sometype'], "getRecordType test");

#getRecordType - undefined hash
$query = SimpleLookupService::QueryObjects::QueryObject->new();
cmp_deeply($query->getRecordType(), undef, "getRecordType - empty record type");

#setRecordTtlAsIso tests

#setRecordTtlAsIso() - pass ISO string
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->setRecordTtlAsIso('PT60M'), 0, "setRecordTtlAsIso() - pass ISO string");

#setRecordTtlAsIso() - pass ISO string array
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->setRecordTtlAsIso(['PT60M']), 0,"setRecordTtlAsIso() - pass ISO string array");


#setRecordTtlAsIso() - pass ISO string array > 1
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->setRecordTtlAsIso(['PT60M', 'PT120M']), 0,"setRecordTtlAsIso() - pass ISO string array");


#setRecordTtlAsIso() - pass minutes 
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->setRecordTtlAsIso(60), -1, "setRecordTtlAsIso() - pass minutes");

#setRecordTtlAsIso() - pass minutes array
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->setRecordTtlAsIso([60]), -1, "setRecordTtlAsIso() - pass minutes array");


#setRecordTtlAsIso() - pass array with size >1
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->setRecordTtlAsIso([60, 'PT60M']), -1, "setRecordTtlAsIso() - pass array with size >1");


#getRecordTtlAsIso
#getRecordTtlAsIso test
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->setRecordTtlAsIso('PT60M');
cmp_deeply( $query->getRecordTtlAsIso(), ['PT60M'], "getRecordTtlAsIso test");

$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->setRecordTtlAsIso(['PT60M','PT120M']);
cmp_deeply( $query->getRecordTtlAsIso(), ['PT60M','PT120M'], "getRecordTtlAsIso array test");

#getRecordTtlAsIso - undefined hash
$query = SimpleLookupService::QueryObjects::QueryObject->new();
cmp_deeply($query->getRecordTtlAsIso(), undef, "getRecordTtlAsIso - empty record ttl");



#setRecordTtlInMinutes tests
#setRecordTtlInMinutes() - pass minutes 
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->setRecordTtlInMinutes(60), 0, "setRecordTtlInMinutes() - pass minutes");

#setRecordTtlInMinutes() - pass minutes array
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->setRecordTtlInMinutes([60]), 0, "setRecordTtlInMinutes() - pass minutes array");

#setRecordTtlInMinutes() - pass ISO string
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->setRecordTtlInMinutes('PT60M'), -1, "setRecordTtlInMinutes() - pass ISO string");

#setRecordTtlInMinutes() - pass ISO string array
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->setRecordTtlInMinutes(['PT60M']), -1,"setRecordTtlInMinutes() - pass ISO string array");


#setRecordTtlInMinutes() - pass array with size >1
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->setRecordTtlInMinutes([60, 'PT60M']), -1, "setRecordTtlInMinutes() - pass array with size >1");


#getRecordTtlInMinutes
#getRecordTtlInMinutes test
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->setRecordTtlInMinutes('60');
cmp_deeply( $query->getRecordTtlInMinutes(), ['60'], "getRecordTtlInMinutes test");

$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->setRecordTtlInMinutes(['60','120']);
cmp_deeply( $query->getRecordTtlInMinutes(), ['60','120'], "getRecordTtlInMinutes array test");

#getRecordTtlInMinutes - undefined hash
$query = SimpleLookupService::QueryObjects::QueryObject->new();
cmp_deeply($query->getRecordTtlInMinutes(), undef, "getRecordTtlInMinutes - empty record ttl");



#setRecordExpires
#setRecordExpires -
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype'});
is($query->setRecordExpires(['2012-12-17T10:14:03.208Z']), 0, "setRecordExpires test array");

$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype'});
is($query->setRecordExpires(['2012-12-17T10:14:03.208Z','2012-12-17T10:14:03.208Z']), 0, "setRecordExpires test array");

#setRecordExpires - undefined hash
$query = SimpleLookupService::QueryObjects::QueryObject->new();
is($query->setRecordExpires('2012-12-17T10:14:03.208Z'), 0, "setRecordExpires test string");



#getRecordExpires
#getRecordExpires -
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype',expires=>'2012-12-17T10:14:03.208Z'});
cmp_deeply($query->getRecordExpires(), ['2012-12-17T10:14:03.208Z'], "getRecordExpires test");

$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype',expires=>['2012-12-17T10:14:03.208Z','2011-12-17T10:14:03.208Z']});
cmp_deeply($query->getRecordExpires(), ['2012-12-17T10:14:03.208Z','2011-12-17T10:14:03.208Z'], "getRecordExpires array test");

#getRecordExpires - undefined hash
$query = SimpleLookupService::QueryObjects::QueryObject->new();
cmp_deeply($query->getRecordExpires(), undef, "getRecordExpires - undefined hash");


#getRecordExpiresAsUnixTS
#getRecordExpiresAsUnixTS -
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype',expires=>'2012-12-17T10:14:03.208Z'});
cmp_deeply($query->getRecordExpiresAsUnixTS(), [1355739243], "getRecordExpiresAsUnixTS test");

$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype',expires=>['2012-12-17T10:14:03.208Z','2011-12-17T10:14:03.208Z']});
cmp_deeply($query->getRecordExpiresAsUnixTS(), [1355739243,1324116843], "getRecordExpiresAsUnixTS array test");

#getRecordExpires - undefined hash
$query = SimpleLookupService::QueryObjects::QueryObject->new();
cmp_deeply($query->getRecordExpiresAsUnixTS(), undef, "getRecordExpiresAsUnixTS - undefined hash");


#setRecordUri
#setRecordUri - array
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype', uri=>'lookup/service/aadbce-12345-adf34'});
is($query->setRecordUri(['lookup/service/aadbce-12345-adf34']), 0, "setRecordUri - array");

#setRecordUri - string
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype'});
is($query->setRecordUri('lookup/service/aadbce-12345-adf34'), 0, "setRecordUri - string");

#getRecordUri
#getRecordUri - returns value
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype', uri=>'lookup/service/aadbce-12345-adf34'});
cmp_deeply($query->getRecordUri(), ['lookup/service/aadbce-12345-adf34'], "getRecordUri - value defined");

#getRecordUri - returns undef
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype'});
cmp_deeply($query->getRecordUri(), undef, "getRecordUri - value undefined");


#setOperator
#setOperator - array - all
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype', uri=>'lookup/service/aadbce-12345-adf34'});
is($query->setOperator(['all']), 0, "setOperator - array - all");

#setOperator - string - all
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype'});
is($query->setOperator('all'), 0, "setRecordOperator - string - all");

#setOperator - array - any
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype', uri=>'lookup/service/aadbce-12345-adf34'});
is($query->setOperator(['any']), 0, "setOperator - array - any");

#setOperator - string - any
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype'});
is($query->setOperator('any'), 0, "setRecordOperator - string - any");

#setOperator - array - something - something
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype', uri=>'lookup/service/aadbce-12345-adf34'});
is($query->setOperator(['something']), -1, "setOperator - array - all");

#setOperator - string
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype'});
is($query->setOperator('something'), -1, "setRecordOperator - string - all");

#setOperator - array >1
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype'});
is($query->setOperator(['all', 'any']), -1, "setRecordOperator - string - array > 1");

#setOperator - array >1
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype'});
is($query->setOperator(['all', 'something']), -1, "setRecordOperator - string - array > 1");

#getOperator
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype'});
$query->setOperator(['all']);
cmp_deeply($query->getOperator(), ['all'], "getOperator - returns value");

$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>'sometype'});
cmp_deeply($query->getOperator(), undef, "getOperator - returns undef");


#setKeyOperator
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>['sometype','sometype1']});
is($query->setKeyOperator({key=> 'type',operator=>['all']}), 0, "setKeyOperator");

#getKeyOperator
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init({type=>['sometype','sometype1']});
$query->setKeyOperator({key=> 'type',operator=>['all']});
cmp_deeply($query->getKeyOperator('type'), ['all'], "getKeyOperator - returns value");


#toURLParameters
#toURLParameters - empty
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init();
is($query->toURLParameters(),'',"toURLParameters - empty parameters");

#toURLParameters - single values initialized as string
#this test may result in error -  if so check manually
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init(type=>'sometype', expires=>'2012-12-17T10:14:03.208Z', ttl=>'PT60M', uri=>'lookup/service/aadbce-12345-adf34');
is($query->toURLParameters(),'?ttl=PT60M&type=sometype&expires=2012-12-17T10:14:03.208Z&uri=lookup/service/aadbce-12345-adf34',"toURLParameters - parameters");

#toURLParameters - single values as arrays
#this test may result in error -  if so check manually
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init(type=>['sometype'], expires=>['2012-12-17T10:14:03.208Z'], ttl=>['PT60M'], uri=>['lookup/service/aadbce-12345-adf34']);
is($query->toURLParameters(),'?ttl=PT60M&type=sometype&expires=2012-12-17T10:14:03.208Z&uri=lookup/service/aadbce-12345-adf34',"toURLParameters - parameters as array");


#toURLParameters - multiple values
#this test may result in error -  if so check manually
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init(type=>['sometype','sometype1'], expires=>['2012-12-17T10:14:03.208Z'], ttl=>['PT60M'], uri=>['lookup/service/aadbce-12345-adf34']);
is($query->toURLParameters(),'?ttl=PT60M&type=sometype,sometype1&expires=2012-12-17T10:14:03.208Z&uri=lookup/service/aadbce-12345-adf34',"toURLParameters - parameters as array");


#toURLParameters - operator key
#this test may result in error -  if so check manually
$query = SimpleLookupService::QueryObjects::QueryObject->new();
$query->init(type=>['sometype','sometype1'], expires=>['2012-12-17T10:14:03.208Z'], ttl=>['PT60M'], uri=>['lookup/service/aadbce-12345-adf34']);
$query->setOperator('all');
is($query->toURLParameters(),'?operator=all&ttl=PT60M&type=sometype,sometype1&expires=2012-12-17T10:14:03.208Z&uri=lookup/service/aadbce-12345-adf34',"toURLParameters - parameters as array");
