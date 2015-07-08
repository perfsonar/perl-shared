package SimpleLookupService::Records::Network::Service;

=head1 NAME

SimpleLookupService::Records::Network::Service - Class that deals records that are network services

=head1 DESCRIPTION

A base class for network services. it defines fields like service-name, service-locator, host and so on. host and contact details 
are references to other records.

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
    my %parameters = validate( @args, { serviceLocator => 1, serviceType => 1, 
    									serviceName => 0, serviceVersion => 0, authnType => 0, 
    									serviceHost => 0, domains => 0, administrators => 0, 
    									siteName => 0 , city => 0, region => 0,
    									country => 0, zipCode => 0, latitude =>0, longitude => 0 } );
    
    $self->SUPER::init(type=>(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_SERVICE)); 
    
    my $returnVal = $self->setServiceType($parameters{serviceType});
    if($returnVal <0){
    		cluck "Error initializing Service record";
    		return $returnVal;
    }
    
    $returnVal = 0;
    $returnVal = $self->setServiceLocators($parameters{serviceLocator});
    if($returnVal <0){
    		cluck "Error initializing Service record";
    		return $returnVal;
    }
    
    if(defined $parameters{serviceName}){
    	my $ret = $self->setServiceName($parameters{serviceName});
    	if($ret <0){
    		cluck "Error initializing Service record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{serviceVersion}){
    	my $ret = $self->setServiceVersion($parameters{serviceVersion});
    	if($ret <0){
    		cluck "Error initializing Service record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{serviceHost}){
    	my $ret = $self->setServiceHost($parameters{serviceHost});
    	if($ret <0){
    		cluck "Error initializing Service record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{domains}){
    	my $ret = $self->setDNSDomains($parameters{domains});
    	if($ret <0){
    		cluck "Error initializing Service record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{administrators}){
    	my $ret = $self->setServiceAdministrators($parameters{administrators});
    	if($ret <0){
    		cluck "Error initializing Service record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{authnType}){
    	my $ret = $self->setAuthnType($parameters{authnType});
    	if($ret <0){
    		cluck "Error initializing Service record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{siteName}){
    	my $ret = $self->setSiteName($parameters{siteName});
    	if($ret <0){
    		cluck "Error initializing Service record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{city}){
    	my $ret = $self->setCity($parameters{city});
    	if($ret <0){
    		cluck "Error initializing Service record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{region}){
    	my $ret = $self->setRegion($parameters{region});
    	if($ret <0){
    		cluck "Error initializing Service record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{country}){
    	my $ret = $self->setCountry($parameters{country});
    	if($ret <0){
    		cluck "Error initializing Service record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{zipCode}){
    	my $ret = $self->setZipCode($parameters{zipCode});
    	if($ret <0){
    		cluck "Error initializing Service record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{latitude}){
    	my $ret = $self->setLatitude($parameters{latitude});
    	if($ret <0){
    		cluck "Error initializing Service record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{longitude}){
    	my $ret = $self->setLongitude($parameters{longitude});
    	if($ret <0){
    		cluck "Error initializing Service record";
    		return $ret;
    	}
    }
    
    return 0;
}

 sub getServiceName {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_NAME)};
}

sub setServiceName {
    my ( $self, $value ) = @_;
    
    if(ref($value) eq 'ARRAY' && scalar @{$value} > 1){
    		cluck "Service Name array size cannot be > 1";
    		return -1;
    }
    	
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    	
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_NAME), value=>$value  );

    
}

sub getServiceType{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_TYPE)};
}

sub setServiceType {
    my ( $self, $value ) = @_;
    
    if(ref($value) eq 'ARRAY' && scalar @{$value} > 1){
    		cluck "Service Type size cannot be > 1";
    		return -1;
    }
    	
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_TYPE), value=>$value  );

}

sub getServiceVersion{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_VERSION)};
}

sub setServiceVersion {
    my ( $self, $value ) = @_;
    
    if(ref($value) eq 'ARRAY' && scalar @{$value} > 1){
    		cluck "Service Version array size cannot be > 1";
    		return -1;
    }
    	
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_VERSION), value=>$value  );

    
}  

sub getServiceHost{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_HOST)};
}

sub setServiceHost {
    my ( $self, $value ) = @_;
    
    if(ref($value) eq 'ARRAY' && scalar @{$value} > 1){
    		cluck "Service Host array size cannot be > 1";
    		return -1;
    }
    	
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_HOST), value=>$value  );

    
}  
    
sub getServiceLocators{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_LOCATOR)};
}

sub setServiceLocators {
    my ( $self, $value ) = @_;
    	
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_LOCATOR), value=>$value  );

    
}   

sub getServiceAdministrators{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_ADMINISTRATORS)};
}

sub setServiceAdministrators{
    my ( $self, $value ) = @_;

    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_ADMINISTRATORS), value=>$value  );

    
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

sub getAuthnType{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_AUTHN_TYPE)};
}

sub setAuthnType {
    my ( $self, $value ) = @_;
    	
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_AUTHN_TYPE), value=>$value  );
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
