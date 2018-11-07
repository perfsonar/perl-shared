#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($RealBin);
use lib ("$RealBin/../lib");
use Test::More 'no_plan';
use Test::Deep;

use Crypt::OpenSSL::X509;

use SimpleLookupService::Records::Record;

my $record = SimpleLookupService::Records::Record->new();
#sign records
my $perlDS = {
	"ttl"=>["PT30M"],
	"type"=>["sometype1"],
	"uri"=>["lookup/service/aadbce-12345-adf34"],
	"expires"=>["2012-12-12:23-33-23Z"]
};
$record = SimpleLookupService::Records::Record->new();
$record->fromHashRef($perlDS);
my $private_key_file = "$RealBin/input/recordsign_test_key.pem";
my $private_key = _get_key_string($private_key_file);
$record->addsign($private_key, "test1");

print $record->toJson;
my $recordHash = $record->getRecordHash;

print "\n\n";

$record = SimpleLookupService::Records::Record->new();
$record->fromHashRef($recordHash);

my $certificate = "$RealBin/input/recordsign_test.crt";

my $x509 = Crypt::OpenSSL::X509->new_from_file($certificate);

my $public_key = $x509->pubkey();
#
is($record->verify($public_key), 0, "verify signing of records");

sub _get_key_string {
	my ($key_file) = @_;
	my $key_string = '';
	open(my $fh, '<:encoding(UTF-8)', $key_file);
	while (my $row = <$fh>) {
		$key_string .= $row;
	}
	return $key_string;
}


