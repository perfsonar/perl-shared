package perfSONAR_PS::Client::LS::PSRecords::PSService;

=head1 NAME

perfSONAR_PS::Client::LS::PSRecords::PSService - Defines perfSONAR service record

=head1 DESCRIPTION

A base class for perfSONAR services. It inherits SimpleLookupService::Records::Network::Service. It defines few perfSONAR
specific keys

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use base 'SimpleLookupService::Records::Network::Service';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames;
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyValues;


sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { serviceLocator => 1, serviceType => 1, 
    									serviceName => 0, serviceVersion => 0, authnType => 0,
    									serviceHost => 0, domains => 0, administrators => 0, 
    									siteName => 0 , city => 0, region => 0,
    									country => 0, zipCode => 0, latitude =>0, longitude => 0} );
    
    my $res = $self->SUPER::init(%parameters); 
    
    return $res;
}

sub getServiceEventType {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSSERVICE_EVENTTYPES)};
}

sub setServiceEventType {
    my ( $self, $value ) = @_;
    return $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSSERVICE_EVENTTYPES), value=>$value  );
}

# to be used only with MA
sub getMAType{
	my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_MA_TYPE)};
}

sub setMAType{
 	my ( $self, $value ) = @_;
    return $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_MA_TYPE), value=>$value  );
    
}

sub getMATests{
	my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_MA_TESTS)};
}

sub setMATests{
 	my ( $self, $value ) = @_;
    return $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_MA_TESTS), value=>$value  );
    
}

# to be used only with topology service
sub getTopologyDomain{
	my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_TS_DOMAINS)};
}


sub setTopologyDomain{
 	my ( $self, $value ) = @_;
    return $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_TS_DOMAINS), value=>$value  );
    
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

sub getBWCTLTools {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_BWCTL_TOOLS)};
}

sub setBWCTLTools {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_BWCTL_TOOLS), value=>$value  );  
	return $ret;
}
