package SimpleLookupService::Records::Network::PSTest;

=head1 NAME

SimpleLookupService::Records::Network::PSTest -Defines the PSTest record

=head1 DESCRIPTION

A base class for test records. it defines fields like test-name, test-source, test-destination and so on. 
are references to other records.

=cut

use strict;
use warnings;

our $VERSION = 3.2;

use base 'SimpleLookupService::Records::Record';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use SimpleLookupService::Keywords::KeyNames;
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames;
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyValues;


sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { eventType => 1, source => 1, destination => 1 } );
    
    $self->SUPER::init(type=>(SimpleLookupService::Keywords::PSValues::LS_VALUE_TYPE_PSTEST)); 
    
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::PSKeyNames::LS_KEY_PSTEST_SOURCE), value=>$parameters{source}  );
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::PSKeyNames::LS_KEY_PSTEST_DESTINATION), value=>$parameters{destination}  );
    
    return 0;
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
