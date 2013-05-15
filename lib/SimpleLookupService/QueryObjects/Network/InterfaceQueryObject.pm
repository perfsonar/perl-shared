package SimpleLookupService::QueryObjects::Network::InterfaceQueryObject;

=head1 NAME

SimpleLookupService::QueryObjects::Network::InterfaceQueryObject - Query Object for Network interfaces

=head1 DESCRIPTION

Query Object for Network services

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use base 'SimpleLookupService::QueryObjects::QueryObject';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use SimpleLookupService::Keywords::KeyNames;
use SimpleLookupService::Keywords::Values;


sub init {
    my ( $self, @args ) = @_;
    
    $self->SUPER::init(type=>(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_INTERFACE)); 
    
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

sub getInterfaceMTU {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_MTU)};
}

sub setInterfaceMTU {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_INTERFACE_MTU), value=>$value  );
    return $ret;
}
1;
