package SimpleLookupService::Records::Network::Host;

=head1 NAME

SimpleLookupService::Records::Network::Host - Class that deals records that are network services

=head1 DESCRIPTION

A base class for network host. it defines fields like host-name, interface, memory, location and so on. interface is a reference to
another record

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
    my %parameters = validate( @args, { hostName => 1, memory => 0, 
    									processorSpeed =>0, processorCount =>0, processorCore => 0,
    									cpuId => 0, osName=>0, osVersion=>0, osKernel => 0, 
    									interfaces =>0, tcpCongestionAlgorithm =>0,
    									 tcpMaxBufferSend =>0, tcpAutoMaxBufferSend =>0, 
    									 tcpMaxBufferRecv =>0, tcpAutoMaxBufferRecv =>0, 
    									 tcpMaxBacklog =>0, tcpMaxAchievable =>0,
    									 vm=> 0, manufacturer=> 0,, productName=> 0, administrators=>0, domains =>0,
    									 siteName => 0 , city => 0, region => 0,
    									 country => 0, zipCode => 0, latitude =>0, longitude => 0 } );
    
    $self->SUPER::init(type=>(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_HOST)); 
    
   if(defined $parameters{hostName}){
    	my $ret = $self->setHostName($parameters{hostName});
    	if($ret <0){
    		cluck "Error initializing Service record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{memory}){
    	my $ret = $self->setHardwareMemory($parameters{memory});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{processorSpeed}){
    	my $ret = $self->setProcessorSpeed($parameters{processorSpeed});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{processorCount}){
    	my $ret = $self->setProcessorCount($parameters{processorCount});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{processorCore}){
    	my $ret = $self->setProcessorCore($parameters{processorCore});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{cpuId}){
    	my $ret = $self->setCpuId($parameters{cpuId});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    
    if(defined $parameters{osName}){
    	my $ret = $self->setOSName($parameters{osName});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{osVersion}){
    	my $ret = $self->setOSVersion($parameters{osVersion});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{osKernel}){
    	my $ret = $self->setOSKernel($parameters{osKernel});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{interfaces}){
    	my $ret = $self->setInterfaces($parameters{interfaces});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{tcpCongestionAlgorithm}){
    	my $ret = $self->setTcpCongestionAlgorithm($parameters{tcpCongestionAlgorithm});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    
    if(defined $parameters{tcpMaxBufferSend}){
    	my $ret = $self->setTcpMaxBufferSend($parameters{tcpMaxBufferSend});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{tcpMaxBufferRecv}){
    	my $ret = $self->setTcpMaxBufferRecv($parameters{tcpMaxBufferRecv});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{tcpAutoMaxBufferSend}){
    	my $ret = $self->setTcpAutotuneMaxBufferSend($parameters{tcpAutoMaxBufferSend});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{tcpAutoMaxBufferRecv}){
    	my $ret = $self->setTcpAutotuneMaxBufferRecv($parameters{tcpAutoMaxBufferRecv});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{tcpMaxBacklog}){
    	my $ret = $self->setTcpMaxBacklog($parameters{tcpMaxBacklog});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{tcpMaxAchievable}){
    	my $ret = $self->setTcpMaxAchievable($parameters{tcpMaxAchievable});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{vm}){
    	my $ret = $self->setVm($parameters{vm});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{manufacturer}){
    	my $ret = $self->setManufacturer($parameters{manufacturer});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    	
    if(defined $parameters{productName}){
    	my $ret = $self->setProductName($parameters{productName});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }

    if(defined $parameters{domains}){
    	my $ret = $self->setDNSDomains($parameters{domains});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{administrators}){
    	my $ret = $self->setHostAdministrators($parameters{administrators});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{siteName}){
    	my $ret = $self->setSiteName($parameters{siteName});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{city}){
    	my $ret = $self->setCity($parameters{city});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{region}){
    	my $ret = $self->setRegion($parameters{region});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{country}){
    	my $ret = $self->setCountry($parameters{country});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{zipCode}){
    	my $ret = $self->setZipCode($parameters{zipCode});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{latitude}){
    	my $ret = $self->setLatitude($parameters{latitude});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{longitude}){
    	my $ret = $self->setLongitude($parameters{longitude});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
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

sub getCpuId {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_CPUID)};
}

sub setCpuId {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_HARDWARE_CPUID), value=>$value  );
    
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

sub getTcpMaxBufferSend {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXBUFFER_SEND)};
}

sub setTcpMaxBufferSend {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXBUFFER_SEND), value=>$value  );
    
}

sub getTcpMaxBufferRecv {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXBUFFER_RECV)};
}

sub setTcpMaxBufferRecv {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXBUFFER_RECV), value=>$value  );
    
}

sub getTcpAutotuneMaxBufferSend {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_AUTOTUNEMAXBUFFER_SEND)};
}

sub setTcpAutotuneMaxBufferSend {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_AUTOTUNEMAXBUFFER_SEND), value=>$value  );
    
}

sub getTcpAutotuneMaxBufferRecv {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_AUTOTUNEMAXBUFFER_RECV)};
}

sub setTcpAutotuneMaxBufferRecv {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_AUTOTUNEMAXBUFFER_RECV), value=>$value  );
    
}

sub getTcpMaxBacklog {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXBACKLOG)};
}

sub setTcpMaxBacklog {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXBACKLOG), value=>$value  );
    
}

sub getTcpMaxAchievable {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXACHIEVABLE)};
}

sub setTcpMaxAchievable {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_NET_TCP_MAXACHIEVABLE), value=>$value  );
    
}

sub getVm {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_VM)};
}

sub setVm {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_VM), value=>$value  );
    
}

sub getManufacturer {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_MANUFACTURER)};
}

sub setManufacturer {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_MANUFACTURER), value=>$value  );
    
}

sub getProductName {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_PRODUCT_NAME)};
}

sub setProductName {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_PRODUCT_NAME), value=>$value  );
    
}

sub getHostAdministrators{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_ADMINISTRATORS)};
}

sub setHostAdministrators{
    my ( $self, $value ) = @_;

    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_HOST_ADMINISTRATORS), value=>$value  );   
    
}   

sub getDNSDomains{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_GROUP_DOMAINS)};
}

sub setDNSDomains {
    my ( $self, $value ) = @_;
    	
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_GROUP_DOMAINS), value=>$value  );

    
}

sub getSiteName{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_SITENAME)};
}

sub setSiteName {
    my ( $self, $value ) = @_;
    
    if(ref($value) eq 'ARRAY' && scalar @{$value} > 1){
    		cluck "Site Name array size cannot be > 1";
    		return -1;
    }
    	
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_SITENAME), value=>$value  );

    
}    

sub getCity{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_CITY)};
}

sub setCity {
    my ( $self, $value ) = @_;
    
    if(ref($value) eq 'ARRAY' && scalar @{$value} > 1){
    		cluck "City array size cannot be > 1";
    		return -1;
    }
    	
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_CITY), value=>$value  );

    
}

sub getRegion{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_STATE)};
}

sub setRegion {
    my ( $self, $value ) = @_;
    
    if(ref($value) eq 'ARRAY' && scalar @{$value} > 1){
    		cluck "Region array size cannot be > 1";
    		return -1;
    }
    	
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_STATE), value=>$value  );
    
    
}

sub getCountry{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_COUNTRY)};
}

sub setCountry {
    my ( $self, $value ) = @_;
        if(ref($value) eq 'ARRAY' && scalar @{$value} > 1){
    		cluck "Country array size cannot be > 1";
    		return -1;
    }
    	
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    
    if(length $value->[0] > 2){
    	cluck "Country should be 2 digit ISO 3166 code";
    	return -1;
    }
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_COUNTRY), value=>$value  );
    
    
}

sub getZipCode{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_CODE)};
}

sub setZipCode {
    my ( $self, $value ) = @_;
    
        if(ref($value) eq 'ARRAY' && scalar @{$value} > 1){
    		cluck "Zip Code array size cannot be > 1";
    		return -1;
    }
    	
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_CODE), value=>$value  );
    
}

sub getLatitude{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_LATITUDE)};
}

sub setLatitude {
    my ( $self, $value ) = @_;
    
    if(ref($value) eq 'ARRAY' && scalar @{$value} > 1){
    		cluck "Latitude array size cannot be > 1";
    		return -1;
    }
    	
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    
    unless($value->[0]>= -90 && $value->[0]<=90){
    	cluck "Latitude should be between -90 to 90";
    	return -1;
    }
    
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_LATITUDE), value=>$value  );
    
}

sub getLongitude{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_LONGITUDE)};
}

sub setLongitude {
    my ( $self, $value ) = @_;
    
        if(ref($value) eq 'ARRAY' && scalar @{$value} > 1){
    		cluck "Longitude array size cannot be > 1";
    		return -1;
    }
    	
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    
    unless($value->[0]>= -180 && $value->[0]<=180){
    	cluck "Longitude should be between -180 to 180";
    	return -1;
    }
    
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_LOCATION_LONGITUDE), value=>$value  );
    
}
1;
