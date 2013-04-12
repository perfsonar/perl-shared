package SimpleLookupService::QueryObjects::Network::HostQueryObject;

=head1 NAME

SimpleLookupService::QueryObjects::Network::HostQueryObject - Query Object for network hosts

=head1 DESCRIPTION

Query Object for Network hosts

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
    
    $self->SUPER::init(type=>(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_HOST)); 
    
    return 0;
}

sub getHostName {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NAME)};
}

sub setHostName {
    my ( $self, $value ) = @_;
    my $ret =  $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NAME), value=>$value  );
    return $ret;
    
}

sub getHardwareMemory {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_MEMORY)};
}

sub setHardwareMemory {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_MEMORY), value=>$value  );
    return $ret;
}

sub getProcessorSpeed {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_PROCESSORSPEED)};
}

sub setProcessorSpeed {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_PROCESSORSPEED), value=>$value  );
    return $ret;
}

sub getProcessorCount {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_PROCESSORCOUNT)};
}

sub setProcessorCount {
    my ( $self, $value ) = @_;
    my $ret  = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_PROCESSORCOUNT), value=>$value  );
    return $ret;
}

sub getProcessorCore {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_PROCESSORCORE)};
}

sub setProcessorCore {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_PROCESSORCORE), value=>$value  );
    return $ret;
}

sub getOSName {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_OS_NAME)};
}

sub setOSName {
    my ( $self, $value ) = @_;
    my $ret  = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_OS_NAME), value=>$value  );
    return $ret;
}

sub getOSVersion {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_OS_VERSION)};
}

sub setOSVersion {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_OS_VERSION), value=>$value  );
    return $ret;
}

sub getOSKernel {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_OS_KERNEL)};
}

sub setOSKernel {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_OS_KERNEL), value=>$value  );
    return $ret;
}

sub getInterfaces {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_INTERFACES)};
}

sub setInterfaces {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_INTERFACES), value=>$value  );
    return $ret;
}

sub getTcpCongestionAlgorithm {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_CONGESTIONALGORITHM)};
}

sub setTcpCongestionAlgorithm {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_CONGESTIONALGORITHM), value=>$value  );
    return $ret;
}

sub getTcpMaxBufferSend {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXBUFFER_SEND)};
}

sub setTcpMaxBufferSend {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXBUFFER_SEND), value=>$value  );
    return $ret;
}

sub getTcpMaxBufferRecv {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXBUFFER_RECV)};
}

sub setTcpMaxBufferRecv {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXBUFFER_RECV), value=>$value  );
    return $ret;
}

sub getTcpAutotuneMaxBufferSend {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_AUTOTUNEMAXBUFFER_SEND)};
}

sub setTcpAutotuneMaxBufferSend {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_AUTOTUNEMAXBUFFER_SEND), value=>$value  );
    return $ret;
}

sub getTcpAutotuneMaxBufferRecv {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_AUTOTUNEMAXBUFFER_RECV)};
}

sub setTcpAutotuneMaxBufferRecv {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_AUTOTUNEMAXBUFFER_RECV), value=>$value  );
    return $ret;
}

sub getTcpMaxBacklog {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXBACKLOG)};
}

sub setTcpMaxBacklog {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXBACKLOG), value=>$value  );
    return $ret;
}
sub getHostAdministrators{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_ADMINISTRATORS)};
}

sub setHostAdministrators{
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_ADMINISTRATORS), value=>$value  );
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

sub getSiteName{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_SITENAME)};
}

sub setSiteName {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_SITENAME), value=>$value  );
    return $ret;
}    

sub getCity{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_CITY)};
}

sub setCity {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_CITY), value=>$value  );
    return $ret;
}

sub getRegion{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_STATE)};
}

sub setRegion {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_STATE), value=>$value  );
    return $ret;
}

sub getCountry{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_COUNTRY)};
}

sub setCountry {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_COUNTRY), value=>$value  );
    return $ret;
}

sub getZipCode{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_CODE)};
}

sub setZipCode {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_CODE), value=>$value  );
    return $ret;
}

sub getLatitude{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_LATITUDE)};
}

sub setLatitude {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_LATITUDE), value=>$value  );
    return $ret;
}

sub getLongitude{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_LONGITUDE)};
}

sub setLongitude {
    my ( $self, $value ) = @_;
    my $ret = $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_LONGITUDE), value=>$value  );
    return $ret;
}
1;
