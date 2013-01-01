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
is($record->init({type=>'sometype', uri=>'lookup/service/aadbce-12345-adf34', expires=>'2012-12-12:23-33-23Z', ttl=>'1440'}), -1, "init() - record type, uri, expires, ttl as minutes");

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



#getRecordExpires
#getRecordExpires -
$record = SimpleLookupService::Records::Record->new();
$record->init({type=>'sometype',expires=>'2012-12-17T10:14:03.208Z'});
cmp_deeply($record->getRecordExpires(), ['2012-12-17T10:14:03.208Z'], "getRecordExpires test");

#getRecordExpires - undefined hash
$record = SimpleLookupService::Records::Record->new();
cmp_deeply($record->getRecordExpires(), undef, "getRecordExpires - undefined hash");

#getRecordExpiresAsUnixTS
#getRecordExpiresAsUnixTS -
$record = SimpleLookupService::Records::Record->new();
$record->init({type=>'sometype',expires=>'2012-12-17T10:14:03.208Z'});
cmp_deeply($record->getRecordExpiresAsUnixTS(), [1355739243], "getRecordExpiresAsUnixTS test");

#getRecordExpires - undefined hash
$record = SimpleLookupService::Records::Record->new();
cmp_deeply($record->getRecordExpiresAsUnixTS(), undef, "getRecordExpiresAsUnixTS - undefined hash");


#getRecordUri
#getRecordUri - returns value
$record = SimpleLookupService::Records::Record->new();
$record->init({type=>'sometype', uri=>'lookup/service/aadbce-12345-adf34'});
cmp_deeply($record->getRecordUri(), ['lookup/service/aadbce-12345-adf34'], "getRecordUri - value defined");

#getRecordUri - returns undef
$record = SimpleLookupService::Records::Record->new();
$record->init({type=>'sometype'});
cmp_deeply($record->getRecordUri(), undef, "getRecordUri - value undefined");



#setRecordTtlAsIso tests

#setRecordTtlAsIso() - pass ISO string
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordTtlAsIso('PT60M'), 0, "setRecordTtlAsIso() - pass ISO string");

#setRecordTtlAsIso() - pass ISO string array
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordTtlAsIso(['PT60M']), 0,"setRecordTtlAsIso() - pass ISO string array");


#setRecordTtlAsIso() - pass minutes 
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordTtlAsIso(60), -1, "setRecordTtlAsIso() - pass minutes");

#setRecordTtlAsIso() - pass minutes array
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordTtlAsIso([60]), -1, "setRecordTtlAsIso() - pass minutes array");


#setRecordTtlAsIso() - pass array with size >1
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordTtlAsIso([60, 'PT60M']), -1, "setRecordTtlAsIso() - pass array with size >1");


#getRecordTtlAsIso
#getRecordTtlAsIso test
$record = SimpleLookupService::Records::Record->new();
$record->setRecordTtlAsIso('PT60M');
cmp_deeply( $record->getRecordTtlAsIso(), ['PT60M'], "getRecordTtlAsIso test");

#getRecordTtlAsIso - undefined hash
$record = SimpleLookupService::Records::Record->new();
cmp_deeply($record->getRecordTtlAsIso(), undef, "getRecordTtlAsIso - empty record ttl");



#setRecordTtlInMinutes tests
#setRecordTtlInMinutes() - pass minutes 
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordTtlInMinutes(60), 0, "setRecordTtlInMinutes() - pass minutes");

#setRecordTtlInMinutes() - pass minutes array
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordTtlInMinutes([60]), 0, "setRecordTtlInMinutes() - pass minutes array");

#setRecordTtlInMinutes() - pass ISO string
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordTtlInMinutes('PT60M'), -1, "setRecordTtlInMinutes() - pass ISO string");

#setRecordTtlInMinutes() - pass ISO string array
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordTtlInMinutes(['PT60M']), -1,"setRecordTtlInMinutes() - pass ISO string array");


#setRecordTtlInMinutes() - pass array with size >1
$record = SimpleLookupService::Records::Record->new();
is($record->setRecordTtlInMinutes([60, 'PT60M']), -1, "setRecordTtlInMinutes() - pass array with size >1");


#getRecordTtlInMinutes
#getRecordTtlInMinutes test
$record = SimpleLookupService::Records::Record->new();
$record->setRecordTtlInMinutes('60');
cmp_deeply( $record->getRecordTtlInMinutes(), ['60'], "getRecordTtlInMinutes test");

#getRecordTtlInMinutes - undefined hash
$record = SimpleLookupService::Records::Record->new();
cmp_deeply($record->getRecordTtlInMinutes(), undef, "getRecordTtlInMinutes - empty record ttl");


#check toJson - if test fails, check result manually and comment out test
$record = SimpleLookupService::Records::Record->new();
$record->init({type=>'sometype', uri=>'lookup/service/aadbce-12345-adf34', expires=>'2012-12-12:23-33-23Z', ttl=>'PT30M'});
is($record->toJson(), '{"ttl":["PT30M"],"type":["sometype"],"uri":["lookup/service/aadbce-12345-adf34"],"expires":["2012-12-12:23-33-23Z"]}', "toJson() - converts record object to Json");

##check toJson - null value
$record = SimpleLookupService::Records::Record->new();
is($record->toJson(), undef, "toJson() - converts record object to Json");


#fromJson
my $json = '{"ttl":["PT30M"],"type":["sometype"],"uri":["lookup/service/aadbce-12345-adf34"],"expires":["2012-12-12:23-33-23Z"]}';
$record = SimpleLookupService::Records::Record->new();
is($record->fromJson($json), 0, "fromJson() - creates record object from Json");
is($record->toJson(), '{"ttl":["PT30M"],"type":["sometype"],"uri":["lookup/service/aadbce-12345-adf34"],"expires":["2012-12-12:23-33-23Z"]}', "toJson() - converts record object to Json");

$json = '';
$record = SimpleLookupService::Records::Record->new();
is($record->fromJson($json), -1, "fromJson() - creates record object from Json");
is($record->toJson(), undef, "toJson - empty record");


#fromHashRef
my $perlDS = {
	"ttl"=>["PT30M"],
	"type"=>["sometype1"],
	"uri"=>["lookup/service/aadbce-12345-adf34"],
	"expires"=>["2012-12-12:23-33-23Z"]	
};

$record = SimpleLookupService::Records::Record->new();
is($record->fromHashRef($perlDS), 0, "fromHashRef() - creates record object from Hash");
is($record->toJson(), '{"ttl":["PT30M"],"type":["sometype1"],"uri":["lookup/service/aadbce-12345-adf34"],"expires":["2012-12-12:23-33-23Z"]}', "toJson() - converts record object to Json");


#_is_iso
$record = SimpleLookupService::Records::Record->new();
my $ts = "PT30M";
is($record->_is_iso($ts), 1, "_is_iso() - returns true");

$record = SimpleLookupService::Records::Record->new();
$ts = "60";
is($record->_is_iso($ts), 0, "_is_iso() - returns true");


#_iso_to_minutes
$record = SimpleLookupService::Records::Record->new();
$ts = "PT30M";
is($record->_iso_to_minutes($ts), 30, "_iso_to_minutes() - returns 30");


$record = SimpleLookupService::Records::Record->new();
$ts = "PT30W";
is($record->_iso_to_minutes($ts), undef, "_iso_to_minutes() - returns undef");

$record = SimpleLookupService::Records::Record->new();
$ts = " ";
is($record->_iso_to_minutes($ts), undef, "_iso_to_minutes() - returns undef");


#_minutes_to_iso
$record = SimpleLookupService::Records::Record->new();
$ts = "30";
is($record->_minutes_to_iso($ts), 'PT30M', "_minutes_to_iso() - returns PT30M");


$record = SimpleLookupService::Records::Record->new();
$ts = "PT30M";
is($record->_minutes_to_iso($ts), undef, "_minutes_to_iso() - returns undef");

$record = SimpleLookupService::Records::Record->new();
$ts = '';
is($record->_minutes_to_iso($ts), undef, "_minutes_to_iso() - returns undef");


#_isoToUnix
$record = SimpleLookupService::Records::Record->new();
$ts = "2012-12-17T10:14:03.208Z";
is($record->_isoToUnix($ts), '1355739243', "_isToUnix() - returns 1355739243");
