package perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject;

=head1 NAME

perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject - Defines query object for perfSONAR Service

=head1 DESCRIPTION

A base query class for perfSONAR services. It inherits SimpleLookupService::QueryObjects::Network::ServiceQueryObject. It defines few perfSONAR
specific keys

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use base 'SimpleLookupService::QueryObjects::Network::ServiceQueryObject';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames;
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyValues;


sub init {
 my ( $self, @args ) = @_;
    
    $self->SUPER::init(); 
    
    return 0;
}

sub getServiceEventType {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSSERVICE_EVENTTYPES)};
}

sub setServiceEventType {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSSERVICE_EVENTTYPES), value=>$value  );
    return $ret;
}

# to be used only with MA
sub getMAType{
	my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_MA_TYPE)};
}

sub setMAType{
 	my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_MA_TYPE), value=>$value  );
    return $ret;
}

sub getMATests{
	my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_MA_TESTS)};
}

sub setMATests{
 	my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_MA_TESTS), value=>$value  );
    return $ret;
}

# to be used only with topology service
sub getTopologyDomain{
	my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_TS_DOMAINS)};
}


sub setTopologyDomain{
 	my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_TS_DOMAINS), value=>$value  );
    return $ret;
}
