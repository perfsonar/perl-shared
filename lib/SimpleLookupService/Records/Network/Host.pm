package SimpleLookupService::Records::Network::Host;

=head1 NAME

SimpleLookupService::Records::Network::Host - Class that deals records that are network services

=head1 DESCRIPTION

A base class for network host. it defines fields like host-name, interface, memory, location and so on. interface is a reference to
another record

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
    my %parameters = validate( @args, { hostName => 1 } );
    
    $self->SUPER::init(type=>(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_HOST)); 
    
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NAME), value=>$parameters{hostName});
    
    return 0;
}

sub getHostName {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NAME)};
}

sub setHostName {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NAME), value=>$value  );
    
}

sub getHardwareMemory {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_MEMORY)};
}

sub setHardwareMemory {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_MEMORY), value=>$value  );
    
}

sub getProcessorSpeed {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_PROCESSORSPEED)};
}

sub setProcessorSpeed {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_PROCESSORSPEED), value=>$value  );
    
}

sub getProcessorCount {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_PROCESSORCOUNT)};
}

sub setProcessorCount {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_PROCESSORCOUNT), value=>$value  );
    
}

sub getProcessorCore {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_PROCESSORCORE)};
}

sub setProcessorCore {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_PROCESSORCORE), value=>$value  );
    
}

sub getOSName {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_OS_NAME)};
}

sub setOSName {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_OS_NAME), value=>$value  );
    
}

sub getOSVersion {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_OS_VERSION)};
}

sub setOSVersion {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_OS_VERSION), value=>$value  );
    
}

sub getOSKernel {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_OS_KERNEL)};
}

sub setOSKernel {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_OS_KERNEL), value=>$value  );
    
}

sub getInterfaces {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_INTERFACES)};
}

sub setInterfaces {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_INTERFACES), value=>$value  );
    
}

sub getTcpCongestionAlgorithm {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_CONGESTIONALGORITHM)};
}

sub setTcpCongestionAlgorithm {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_CONGESTIONALGORITHM), value=>$value  );
    
}

sub getTcpMaxBuffer {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXBUFFER)};
}

sub setTcpMaxBuffer {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXBUFFER), value=>$value  );
    
}

sub getTcpAutotuneMaxBuffer {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_AUTOTUNEMAXBUFFER)};
}

sub setTcpAutotuneMaxBuffer {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_AUTOTUNEMAXBUFFER), value=>$value  );
    
}

sub getHostAdministrators{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_ADMINISTRATORS)};
}

sub setHostAdministrators{
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_ADMINISTRATORS), value=>$value  );
    
}   
    
sub getDNSDomains{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_GROUP_DOMAINS)};
}

sub setDNSDomains {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_GROUP_DOMAINS), value=>$value  );
    
}

sub getSiteName{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_SITENAME)};
}

sub setSiteName {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_SITENAME), value=>$value  );
    
}    

sub getCity{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_CITY)};
}

sub setCity {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_CITY), value=>$value  );
    
}

sub getRegion{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_STATE)};
}

sub setRegion {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_STATE), value=>$value  );
    
}

sub getCountry{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_COUNTRY)};
}

sub setCountry {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_COUNTRY), value=>$value  );
    
}

sub getZipCode{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_CODE)};
}

sub setZipCode {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_CODE), value=>$value  );
    
}

sub getLatitude{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_LATITUDE)};
}

sub setLatitude {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_LATITUDE), value=>$value  );
    
}

sub getLongitude{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_LONGITUDE)};
}

sub setLongitude {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_LONGITUDE), value=>$value  );
    
}
1;