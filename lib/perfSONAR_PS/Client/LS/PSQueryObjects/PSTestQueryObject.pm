package perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject;

=head1 NAME

perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject - Defines query object for perfSONAR Test

=head1 DESCRIPTION

A base query class for perfSONAR Tests. It inherits SimpleLookupService::QueryObjects::Network::TestQueryObject. It defines few perfSONAR
specific keys

=cut

use strict;
use warnings;

our $VERSION = 3.2;

use base 'SimpleLookupService::QueryObjects::QueryObject';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames;
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyValues;


sub init {
    my ( $self, @args ) = @_;
    
    $self->SUPER::init(type=>(SimpleLookupService::Keywords::PSValues::LS_VALUE_TYPE_PSTEST)); 
    
    return $self;
}

sub getTestName {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::PSKeyNames::LS_KEY_PSTEST_NAME)};
}

sub setTestName {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::PSKeyNames::LS_KEY_PSTEST_NAME), value=>$value  );  
}

sub getSource {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::PSKeyNames::LS_KEY_PSTEST_SOURCE)};
}

sub setSource {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::PSKeyNames::LS_KEY_PSTEST_SOURCE), value=>$value  );  
}

sub getDestination {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::PSKeyNames::LS_KEY_PSTEST_DESTINATION)};
}

sub setDestination {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::PSKeyNames::LS_KEY_PSTEST_DESTINATION), value=>$value  );  
}

sub getEventTypes {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::PSKeyNames::LS_KEY_PSTEST_EVENTTYPES)};
}

sub setEventTypes {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::PSKeyNames::LS_KEY_PSTEST_EVENTTYPES), value=>$value  );  
}

sub getDomains {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::PSKeyNames::LS_KEY_GROUP_DOMAINS)};
}

sub setDomains {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::PSKeyNames::LS_KEY_GROUP_DOMAINS), value=>$value  );  
}

sub getCommunities {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::PSKeyNames::LS_KEY_GROUP_COMMUNITIES)};
}

sub setCommunities {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::PSKeyNames::LS_KEY_GROUP_COMMUNITIES), value=>$value  );  
}
