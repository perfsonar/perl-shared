#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;

use SimpleLookupService::Records::Record;

my $record = SimpleLookupService::Records::Record->new();

#check record creation
ok( defined $record,            "new(record => '$record')" );

#check the class type
ok( $record->isa('SimpleLookupService::Records::Record'), "and it's the right class");

#init() tests
#check init() - record type as string - converts to array
$record = SimpleLookupService::Records::Record->new();
is($record->init({type=>'sometype'}), 0, "init - record type as string");

# init() - record type as array
$record = SimpleLookupService::Records::Record->new();
is($record->init({type=>['sometype']}), 0, "init - record type as array");

#init() - pass array with size >1 - should return -1
$record = SimpleLookupService::Records::Record->new();
is($record->init({type=>['sometype', "sommme"]}), -1, "init - record type as array >1");

#check init() - record type, uri, expires, ttl
$record = SimpleLookupService::Records::Record->new();
is($record->init({type=>'sometype', uri=>'lookup/service/aadbce-12345-adf34', expires=>'2012-12-12:23-33-23Z', ttl=>'PT30M'}), 0, "init() - record type, uri, expires, ttl");

#check init() - record type, uri, expires, ttl
$record = SimpleLookupService::Records::Record->new();
is($record->init({type=>'sometype', uri=>'lookup/service/aadbce-12345-adf34', expires=>'2012-12-12:23-33-23Z', ttl=>'1440'}), 0, "init() - record type, uri, expires, ttl");

#check init() - record type, uri, expires, ttl as arrays
$record = SimpleLookupService::Records::Record->new();
is($record->init({type=>['sometype'], uri=>['lookup/service/aadbce-12345-adf34'], expires=>['2012-12-12:23-33-23Z'], ttl=>['PT30M']}), 0, "init()- record type, uri, expires, ttl as arrays");

#check init() - record type>1, uri, expires, ttl
$record = SimpleLookupService::Records::Record->new();
is($record->init({type=>['sometype', 'xyz'], uri=>['lookup/service/aadbce-12345-adf34'], expires=>['2012-12-12:23-33-23Z'], ttl=>['PT30M']}), -1, "init()- arrays -record type > 1, uri, expires, ttl");

#check init() - record type, uri>1, expires, ttl
$record = SimpleLookupService::Records::Record->new();
is($record->init({type=>['sometype'], uri=>['lookup/service/aadbce-12345-adf34', 'abc'], expires=>['2012-12-12:23-33-23Z'], ttl=>['PT30M']}), -1, "init()- arrays - record type, uri > 1, expires, ttl");

#check init() - record type, uri, expires>1, ttl
$record = SimpleLookupService::Records::Record->new();
is($record->init({type=>['sometype'], uri=>['lookup/service/aadbce-12345-adf34'], expires=>['2012-12-12:23-33-23Z', 'abc'], ttl=>['PT30M']}), -1, "init()- arrays - record type, uri, expires > 1, ttl");

#check init() - record type, uri, expires, ttl > 1
$record = SimpleLookupService::Records::Record->new();
is($record->init({type=>['sometype'], uri=>['lookup/service/aadbce-12345-adf34'], expires=>['2012-12-12:23-33-23Z'], ttl=>['PT30M','abc']}), -1, "init()- arrays - record type, uri, expires, ttl > 1");



# addField() tests
# addField() - key, value
$record = SimpleLookupService::Records::Record->new();
is($record->addField({key=>'somekey', value=>'somevalue'}), 0, "addField - key, value");

# addField() - key as array
$record = SimpleLookupService::Records::Record->new();
is($record->addField({key=>['somekey1','ss'], value=>'somevalue'}), -1, "addField - key as array");

# addField() - value as array
$record = SimpleLookupService::Records::Record->new();
is($record->addField({key=>'somekey2', value=>['somevalue','someval']}), -0, "addField - value as array");


#getValue
#getValue - key found in hash
$record = SimpleLookupService::Records::Record->new();
$record->addField({key=>'somekey2', value=>['somevalue','someval']});
cmp_deeply($record->getValue('somekey2'), ['somevalue','someval'], "getValue - key found in hash");

#getValue - key not found in hash
$record = SimpleLookupService::Records::Record->new();
cmp_deeply($record->getValue('somekey2'), undef, "getValue - key not found in hash");


#getRecordHash
#getRecordHash - hash has elements
$record = SimpleLookupService::Records::Record->new();
$record->init({type=>'sometype', uri=>'lookup/service/aadbce-12345-adf34', expires=>'2012-12-17T10:14:03.208Z', ttl=>'PT30M'});
cmp_deeply($record->getRecordHash(), {type=>['sometype'], uri=>['lookup/service/aadbce-12345-adf34'], expires=>['2012-12-17T10:14:03.208Z'], ttl=>['PT30M']}, "getRecordHash - hash has elements");

#getRecordHash - hash has no elements
$record = SimpleLookupService::Records::Record->new();
cmp_deeply($record->getRecordHash(), undef, "getRecordHash - hash has no elements");



#setRecordType tests
#setRecordType() - pass array
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordType(['sometype1']), 0,"setRecordType() - pass array");

#setRecordType() - pass string - converts to array
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordType('sometype2'), 0, "setRecordType() - pass string - converts to array");

#setRecordType() - pass array with size >1
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordType(['sometype4','sometype3']), -1, "setRecordType() - pass array with size >1");


#getRecordType
#getRecordType test
$record = SimpleLookupService::Records::Record->new();
$record->setRecordType(['sometype']);
cmp_deeply( $record->getRecordType(), ['sometype'], "getRecordType test");

#getRecordType - undefined hash
$record = SimpleLookupService::Records::Record->new();
cmp_deeply($record->getRecordType(), undef, "getRecordType - empty record type");


#setRecordTtl tests
#setRecordTtl() - pass minutes 
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordTtl(60), 0, "setRecordTtl() - pass minutes");

#setRecordTtl() - pass minutes array
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordTtl([60]), 0, "setRecordTtl() - pass minutes array");

#setRecordTtl() - pass ISO string
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordTtl('PT60M'), 0, "setRecordTtl() - pass ISO string");

#setRecordTtl() - pass ISO string array
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordTtl(['PT60M']), 0,"setRecordTtl() - pass ISO string array");

#setRecordTtl() - pass array with size >1
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordTtl([60, 'PT60M']), -1, "setRecordTtl() - pass array with size >1");


#getRecordTtl
#getRecordTtl test
$record = SimpleLookupService::Records::Record->new();
$record->setRecordTtl(60);
cmp_deeply( $record->getRecordTtl(), [60], "getRecordTtl test");


#getRecordTtl test
$record = SimpleLookupService::Records::Record->new();
$record->setRecordTtl('PT60M');
cmp_deeply( $record->getRecordTtl(), [60], "getRecordTtl test");

#getRecordTtl - undefined hash
$record = SimpleLookupService::Records::Record->new();
cmp_deeply($record->getRecordTtl(), undef, "getRecordTtl - empty record ttl");



#getRecordExpires
#getRecordExpires -
$record = SimpleLookupService::Records::Record->new();
$record->init({type=>'sometype',expires=>'2012-12-17T10:14:03.208Z'});
cmp_deeply($record->getRecordExpires(), [1355739243], "getRecordExpires test");

#getRecordExpires - undefined hash
$record = SimpleLookupService::Records::Record->new();
cmp_deeply($record->getRecordExpires(), undef, "getRecordExpires - undefined hash");



#getRecordUri
#getRecordUri - returns value
$record = SimpleLookupService::Records::Record->new();
$record->init({type=>'sometype', uri=>'lookup/service/aadbce-12345-adf34'});
cmp_deeply($record->getRecordUri(), ['lookup/service/aadbce-12345-adf34'], "getRecordUri - value defined");

#getRecordUri - returns undef
$record = SimpleLookupService::Records::Record->new();
$record->init({type=>'sometype'});
cmp_deeply($record->getRecordUri(), undef, "getRecordUri - value undefined");


#check toJson - if test fails, check result manually and comment out test
$record = SimpleLookupService::Records::Record->new();
$record->init({type=>'sometype', uri=>'lookup/service/aadbce-12345-adf34', expires=>'2012-12-12:23-33-23Z', ttl=>'PT30M'});
is($record->toJson(), '{"ttl":["PT30M"],"type":["sometype"],"uri":["lookup/service/aadbce-12345-adf34"],"expires":["2012-12-12:23-33-23Z"]}', "toJson() - converts record object to Json");

##check toJson - null value
$record = SimpleLookupService::Records::Record->new();
is($record->toJson(), undef, "toJson() - converts record object to Json");

#fromJson

#fromHashRef

