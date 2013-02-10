package perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject;

=head1 NAME

perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject - Defines query object for perfSONAR Test

=head1 DESCRIPTION

A base query class for perfSONAR Tests. It inherits SimpleLookupService::QueryObjects::Network::TestQueryObject. It defines few perfSONAR
specific keys

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use base 'SimpleLookupService::QueryObjects::QueryObject';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames;
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyValues;
use SimpleLookupService::Keywords::KeyNames;

use Carp qw(cluck);


sub init {
    my ( $self, @args ) = @_;
    
    $self->SUPER::init(type=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyValues::LS_VALUE_TYPE_PSTEST)); 
    
    return 0;
}

sub getTestName {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSTEST_NAME)};
}

sub setTestName {
    my ( $self, $value ) = @_;
    return $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSTEST_NAME), value=>$value  );  
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
    return $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSTEST_EVENTTYPES), value=>$value  );  
}

sub getDNSDomains {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_GROUP_DOMAINS)};
}

sub setDNSDomains {
    my ( $self, $value ) = @_;
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_GROUP_DOMAINS), value=>$value  );  
}

sub getCommunities {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_GROUP_COMMUNITIES)};
}

sub setCommunities {
    my ( $self, $value ) = @_;
    return $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_GROUP_COMMUNITIES), value=>$value  );  
}
