package perfSONAR_PS::Client::LS::PSRecords::PSService;

=head1 NAME

perfSONAR_PS::Client::LS::PSRecords::PSService - Defines perfSONAR service record

=head1 DESCRIPTION

A base class for perfSONAR services. It inherits SimpleLookupService::Records::Network::Service. It defines few perfSONAR
specific keys

=cut

use strict;
use warnings;

our $VERSION = 3.2;

use base 'SimpleLookupService::Records::Network::Service';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames;
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyValues;


sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { serviceLocator => 1, serviceType => 1 } );
    
    $self->SUPER::init(%parameters); 
    
    return 0;
}

sub getServiceEventType {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSSERVICE_EVENTTYPES)};
}

sub setServiceEventType {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSSERVICE_EVENTTYPES), value=>$value  );
    
}

# to be used only with MA
sub getMAType{
	my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_MA_TYPE)};
}

sub setMAType{
 	my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_MA_TYPE), value=>$value  );
    
}

sub getMATests{
	my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_MA_TESTS)};
}

sub setMATests{
 	my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_MA_TESTS), value=>$value  );
    
}

# to be used only with topology service
sub getTopologyDomain{
	my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_TS_DOMAINS)};
}


sub setTopologyDomain{
 	my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_TS_DOMAINS), value=>$value  );
    
}