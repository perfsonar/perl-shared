#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;

use SimpleLookupService::Client::SimpleLS;
use SimpleLookupService::BulkRenewMessage;
use SimpleLookupService::BulkRenewResponse;
use SimpleLookupService::Client::BulkRenewManager;


#this test suite requires a local instance of lookup service to be running
my $ls_client = SimpleLookupService::Client::SimpleLS->new();
$ls_client->init({host=>'localhost', port => 8090});

$ls_client->connect();

my $message = SimpleLookupService::BulkRenewMessage->new();
$message->init(record_uris => ["lookup/client-test/0a97241f-5207-4487-a1c0-15d506401b09",
    "lookup/client-test/3f68ba64-9a7b-4eac-8cd4-df75674166bf",
    "lookup/client-test/4548db9e-452c-4235-a48f-9fe4a0a5357f",
    "lookup/interface/87c15a2b-bc74-47ca-84ed-8be84b69568b",
    "lookup/client-test/13e4f613-5725-4a9e-8644-8f1364861d38"],
    ttl=>"PT30M");

my $bulk_renew_manager = SimpleLookupService::Client::BulkRenewManager->new();
$bulk_renew_manager->init({server=> $ls_client, message=> $message});
my ($returnVal, $ret_message) = $bulk_renew_manager->renew();
is($returnVal, 0, "check return value");
ok($ret_message->isa('SimpleLookupService::BulkRenewResponse'), "check if response is of type SimpleLookupService::BulkRenewResponse" );

is($ret_message->getTotal(), 5, "check  total count of uris returned in bulk response");
is($ret_message->getRenewed(), 0, "check  renewed count of uris returned in bulk response");
is($ret_message->getFailed(), 5, "check  failed count of uris returned in bulk response");

done_testing();

