package SimpleLookupService::Records::Network::Interface;

=head1 NAME

SimpleLookupService::Records::Network::Interface - Class that deals records that are network interfaces

=head1 DESCRIPTION

A base class for network interface. it defines fields like interface-name, address, mac address, capacity, etc.

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use base 'SimpleLookupService::Records::Record';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use SimpleLookupService::Keywords::KeyNames;
use SimpleLookupService::Keywords::Values;
use Carp qw(cluck);


sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, {interfaceName => 1, interfaceAddresses => 1, subnet => 0, capacity => 0, macAddress=>0, mtu=>0, domains=>0 } );
    
    $self->SUPER::init(type=>(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_INTERFACE)); 
        
    my $returnVal = $self->setInterfaceName($parameters{interfaceName});
    if($returnVal <0){
    		cluck "Error initializing Service record";
    		return $returnVal;
    }
    
    $returnVal = 0;
    $returnVal = $self->setInterfaceAddresses($parameters{interfaceAddresses});
    if($returnVal <0){
    		cluck "Error initializing Service record";
    		return $returnVal;
    }
    
    
    if(defined $parameters{subnet}){
    	my $ret = $self->setInterfaceSubnet($parameters{subnet});
    	if($ret <0){
    		cluck "Error initializing Interface record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{capacity}){
    	my $ret = $self->setInterfaceCapacity($parameters{capacity});
    	if($ret <0){
    		cluck "Error initializing Interface record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{macAddress}){
    	my $ret = $self->setInterfaceMacAddress($parameters{macAddress});
    	if($ret <0){
    		cluck "Error initializing Interface record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{mtu}){
    	my $ret = $self->setInterfaceMTU($parameters{mtu});
    	if($ret <0){
    		cluck "Error initializing Interface record MTU";
    		return $ret;
    	}
    }
    
    if(defined $parameters{domains}){
    	my $ret = $self->setDNSDomains($parameters{domains});
    	if($ret <0){
    		cluck "Error initializing Interface record";
    		return $ret;
    	}
    }
     
    return 0;
}

sub getInterfaceName {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_NAME)};
}

sub setInterfaceName {
    my ( $self, $value ) = @_;
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_NAME), value=>$value  );
    return $ret;
    
}

sub getInterfaceAddresses {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_ADDRESSES)};
}

sub setInterfaceAddresses {
    my ( $self, $value ) = @_;
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_ADDRESSES), value=>$value  );
    return $ret;
}

sub getInterfaceSubnet {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_SUBNET)};
}

sub setInterfaceSubnet {
    my ( $self, $value ) = @_;
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_SUBNET), value=>$value  );
    return $ret;
}

sub getInterfaceCapacity {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_CAPACITY)};
}

sub setInterfaceCapacity {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_CAPACITY), value=>$value  );
    return $ret;
}

sub getInterfaceMTU {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_MTU)};
}

sub setInterfaceMTU {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_MTU), value=>$value  );
    return $ret;
}

sub getInterfaceMacAddress {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_MAC)};
}

sub setInterfaceMacAddress {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_MAC), value=>$value  );
    return $ret;
}

sub getDNSDomains{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_GROUP_DOMAINS)};
}

sub setDNSDomains {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_GROUP_DOMAINS), value=>$value  );
    return $ret;
}
