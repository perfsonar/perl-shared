package perfSONAR_PS::Client::LS::PSRecords::PSTest;

=head1 NAME

SimpleLookupService::Records::Network::PSTest -Defines the PSTest record

=head1 DESCRIPTION

A base class for test records. it defines fields like test-name, test-source, test-destination and so on. 
are references to other records.

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use base 'SimpleLookupService::Records::Record';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use SimpleLookupService::Keywords::KeyNames;
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames;
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyValues;
use Carp qw(cluck);


sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { eventType => 1, source => 1, destination => 1, testname => 0, domains => 0, communities => 0 } );
    
    $self->SUPER::init(type=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyValues::LS_VALUE_TYPE_PSTEST)); 
    
    $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSTEST_SOURCE), value=>$parameters{source}  );
    $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSTEST_DESTINATION), value=>$parameters{destination}  );
    $self->setTestName($parameters{testname}) if($parameters{testname});
    $self->setEventTypes($parameters{eventType}) if($parameters{eventType});
    $self->setCommunities($parameters{communities}) if($parameters{communities});
    $self->setDNSDomains($parameters{domains}) if($parameters{domains});
    
    return 0;
}

sub getTestName {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSTEST_NAME)};
}

sub setTestName {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSTEST_NAME), value=>$value  );  
	return $ret;
}

sub getSource {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSTEST_SOURCE)};
}

sub setSource {
    my ( $self, $value ) = @_;
    if(ref($value) eq "ARRAY" && scalar @{$value} > 1){
    	cluck "Only one destination host can be specified";
    	return -1;
    }
    my $ret = $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSTEST_SOURCE), value=>$value  );  
	return $ret;
}

sub getDestination {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSTEST_DESTINATION)};
}

sub setDestination {
    my ( $self, $value ) = @_;
    if(ref($value) eq "ARRAY" && scalar @{$value} > 1){
    	cluck "Only one destination host can be specified";
    	return -1;
    }
    my $ret = $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSTEST_DESTINATION), value=>$value  );  
	return $ret;
}

sub getEventTypes {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSTEST_EVENTTYPES)};
}

sub setEventTypes {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSTEST_EVENTTYPES), value=>$value  );  
	return $ret;
}

sub getDNSDomains {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_GROUP_DOMAINS)};
}

sub setDNSDomains {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_GROUP_DOMAINS), value=>$value  );  
	return $ret;
}

sub getCommunities {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_GROUP_COMMUNITIES)};
}

sub setCommunities {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_GROUP_COMMUNITIES), value=>$value  );  
	return $ret;
}
1;
