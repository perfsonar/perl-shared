package SimpleLookupService::Records::Network::Interface;

=head1 NAME

SimpleLookupService::Records::Network::Interface - Class that deals records that are network interfaces

=head1 DESCRIPTION

A base class for network interface. it defines fields like interface-name, address, mac address, capacity, etc.

=cut

use strict;
use warnings;

our $VERSION = 3.2;

use base 'SimpleLookupService::Records::Record';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use SimpleLookupService::Keywords::KeyNames;


sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, {interfaceName => 1, interfaceAddresses => 1 } );
    
    $self->SUPER::init(type=>(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_INTERFACE)); 
    
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_NAME), value=>$parameters{interfaceName});
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_ADDRESSES), value=>$parameters{interfaceAddress});
    
    return 0;
}

sub getInterfaceName {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_NAME)};
}

sub setInterfaceName {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_NAME), value=>$value  );
    
}

sub getInterfaceAddresses {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_ADDRESSES)};
}

sub setInterfaceAddresses {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_ADDRESSES), value=>$value  );
    
}

sub getInterfaceSubnet {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_SUBNET)};
}

sub setInterfaceSubnet {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_SUBNET), value=>$value  );
    
}

sub getInterfaceCapacity {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_CAPACITY)};
}

sub setInterfaceCapacity {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_CAPACITY), value=>$value  );
    
}

sub getInterfaceMacAddress {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_MAC)};
}

sub setInterfaceMacAddress {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_MAC), value=>$value  );
    
}

sub getDNSDomains{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_GROUP_DOMAINS)};
}

sub setDNSDomains {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_GROUP_DOMAINS), value=>$value  );
    
}