#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;

use SimpleLookupService::BulkRenewMessage;

my $record = SimpleLookupService::BulkRenewMessage->new();

#check record creation
ok( defined $record,            "new(record => '$record')" );

#check the class type
ok( $record->isa('SimpleLookupService::BulkRenewMessage'), "and it's the right class");

#init() tests
#check init() - record uris and ttl
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->init({record_uris=>['lookup/service/aadbce-12345-adf34', 'lookup/service/aadbce-12345-bcdef'],  ttl=>'PT30M'}), 0, "init() - recorduris, ttl");

#check init() - record uris and ttl
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->init({record_uris=>'lookup/service/aadbce-12345-adf34', ttl=>'PT30M'}), 0, "init() - recorduris, ttl");

#check init() - record uris and ttl as minutes
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->init({record_uris=>'lookup/service/aadbce-12345-adf34', ttl=>'1440'}), -1, "init() - ttl as minutes. returns -1");

#check init() - record uris, ttl as arrays
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->init({record_uris=>['lookup/service/aadbce-12345-adf34'], ttl=>['PT30M']}), 0, "init()- recorduris,  ttl as arrays");

#check init() - record_uris empty uri, ttl
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->init({record_uris=>[], ttl=>['PT30M']}), -1, "init()- record uris < 1,  ttl");

#check init() - record type, uri, expires, ttl > 1
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->init({record_uris=>['lookup/service/aadbce-12345-adf34'], ttl=>['PT30M','abc']}), -1, "init()- ttl > 1");

#getRecordHash
#getRecordHash - hash has elements
$record = SimpleLookupService::BulkRenewMessage->new();
$record->init({record_uris=>['lookup/service/aadbce-12345-adf34', 'lookup/service/aadbce-12345-bcdef'], ttl=>'PT30M'});
cmp_deeply($record->getRecordHash(), {'record-uris'=>['lookup/service/aadbce-12345-adf34', 'lookup/service/aadbce-12345-bcdef'], ttl=>['PT30M']}, "getRecordHash ");

#getRecordHash - hash has no elements
$record = SimpleLookupService::BulkRenewMessage->new();
cmp_deeply($record->getRecordHash(), undef, "getRecordHash - hash has no elements");



#getRecordUris
#getRecordUri - returns value
$record = SimpleLookupService::BulkRenewMessage->new();
$record->init({record_uris=>['lookup/service/aadbce-12345-adf34', 'lookup/service/aadbce-12345-bcdef'], ttl=>'PT30M'});
cmp_deeply($record->getRecordUris(), ['lookup/service/aadbce-12345-adf34', 'lookup/service/aadbce-12345-bcdef'], "getRecordUri - value defined");

#getRecordUri - returns undef
$record =SimpleLookupService::BulkRenewMessage->new();
$record->init({ttl=>'PT30M'});
cmp_deeply($record->getRecordUris(), undef, "getRecordUris - value undefined");



#setRecordTtlAsIso tests

#setRecordTtlAsIso() - pass ISO string
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->setRecordTtlAsIso('PT60M'), 0, "setRecordTtlAsIso() - pass ISO string");

#setRecordTtlAsIso() - pass ISO string array
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->setRecordTtlAsIso(['PT60M']), 0,"setRecordTtlAsIso() - pass ISO string array");


#setRecordTtlAsIso() - pass minutes 
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->setRecordTtlAsIso(60), -1, "setRecordTtlAsIso() - pass minutes");

#setRecordTtlAsIso() - pass minutes array
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->setRecordTtlAsIso([60]), -1, "setRecordTtlAsIso() - pass minutes array");


#setRecordTtlAsIso() - pass array with size >1
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->setRecordTtlAsIso([60, 'PT60M']), -1, "setRecordTtlAsIso() - pass array with size >1");


#getRecordTtlAsIso
#getRecordTtlAsIso test
$record = SimpleLookupService::BulkRenewMessage->new();
$record->setRecordTtlAsIso('PT60M');
cmp_deeply( $record->getRecordTtlAsIso(), ['PT60M'], "getRecordTtlAsIso test");

#getRecordTtlAsIso - undefined hash
$record = SimpleLookupService::BulkRenewMessage->new();
cmp_deeply($record->getRecordTtlAsIso(), undef, "getRecordTtlAsIso - empty record ttl");



#setRecordTtlInMinutes tests
#setRecordTtlInMinutes() - pass minutes 
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->setRecordTtlInMinutes(60), 0, "setRecordTtlInMinutes() - pass minutes");

#setRecordTtlInMinutes() - pass minutes array
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->setRecordTtlInMinutes([60]), 0, "setRecordTtlInMinutes() - pass minutes array");

#setRecordTtlInMinutes() - pass ISO string
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->setRecordTtlInMinutes('PT60M'), -1, "setRecordTtlInMinutes() - pass ISO string");

#setRecordTtlInMinutes() - pass ISO string array
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->setRecordTtlInMinutes(['PT60M']), -1,"setRecordTtlInMinutes() - pass ISO string array");


#setRecordTtlInMinutes() - pass array with size >1
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->setRecordTtlInMinutes([60, 'PT60M']), -1, "setRecordTtlInMinutes() - pass array with size >1");


#getRecordTtlInMinutes
#getRecordTtlInMinutes test
$record = SimpleLookupService::BulkRenewMessage->new();
$record->setRecordTtlInMinutes('60');
cmp_deeply( $record->getRecordTtlInMinutes(), ['60'], "getRecordTtlInMinutes test");

#getRecordTtlInMinutes - undefined hash
$record = SimpleLookupService::BulkRenewMessage->new();
cmp_deeply($record->getRecordTtlInMinutes(), undef, "getRecordTtlInMinutes - empty record ttl");


#check toJson - if test fails, check result manually and comment out test
$record = SimpleLookupService::BulkRenewMessage->new();
$record->init({record_uris=>'lookup/service/aadbce-12345-adf34', ttl=>'PT30M'});
is($record->toJson(), '{"record-uris":["lookup/service/aadbce-12345-adf34"],"ttl":["PT30M"]}', "toJson() - converts record object to Json");

##check toJson - null value
$record = SimpleLookupService::BulkRenewMessage->new();
is($record->toJson(), undef, "toJson() - converts record object to Json");

