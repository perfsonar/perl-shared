package perfSONAR_PS::Client::LS::PSRecords::PSInterface;

=head1 NAME

perfSONAR_PS::Client::LS::PSRecords::PSInterface - Defines perfSONAR network interface record

=head1 DESCRIPTION

A base class for perfSONAR services. It inherits SimpleLookupService::Records::Network::Interface. It defines few perfSONAR
specific keys

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use base 'SimpleLookupService::Records::Network::Interface';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames;
use perfSONAR_PS::Client::LS::PSKeywords::PSKeyValues;


sub init {
    my ( $self, @args ) = @_;
    
    $self->SUPER::init(@args); 
    
    return 0;
}

sub getInterfaceType {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSINTERFACE_TYPE)};
}

sub setInterfaceType {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSINTERFACE_TYPE), value=>$value  );
    
}

sub getUrns {
    my $self = shift;
    return $self->{RECORD_HASH}->{(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSINTERFACE_URNS)};
}

sub setUrns {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames::LS_KEY_PSINTERFACE_URNS), value=>$value  );
    
}
