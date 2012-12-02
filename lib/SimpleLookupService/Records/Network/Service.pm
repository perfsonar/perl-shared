package SimpleLookupService::Records::Network::Service;

=head1 NAME

SimpleLookupService::Records::Network::Service - Class that deals records that are network services

=head1 DESCRIPTION

A base class for network services. it defines fields like service-name, service-locator, host and so on. host and contact details 
are references to other records.

=cut

use strict;
use warnings;

our $VERSION = 3.2;

use base 'SimpleLookupService::Records::Record';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);

use constant {
    LS_KEY_SERVICE_NAME => "service-name",
    LS_KEY_SERVICE_TYPE => "service-type",
    LS_KEY_SERVICE_VERSION => "service-version",
    LS_KEY_SERVICE_LOCATOR => "service-locator",
    LS_KEY_SERVICE_ADMINISTRATORS => "service-administrators",
    LS_KEY_GROUP_DOMAINS => "group-domains",
    LS_KEY_LOCATION_SITENAME => "location-sitename",
    LS_KEY_LOCATION_CITY => "location-city",
    LS_KEY_LOCATION_STATE => "location-state",
    LS_KEY_LOCATION_COUNTRY => "location-country",
    LS_KEY_LOCATION_CODE => "location-code",
    LS_KEY_LOCATION_LATITUDE => "location-latitude",
    LS_KEY_LOCATION_LONGITUDE => "location-longitude"
};


sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { type => 1, serviceLocator => 1, serviceType => 1 } );
    
    $self->SUPER::init(type=>$parameters{type}); 
    
    $self->SUPER::addField(key=>(LS_KEY_SERVICE_TYPE), value=>$parameters{serviceType}  );
    $self->SUPER::addField(key=>(LS_KEY_SERVICE_LOCATOR), value=>$parameters{serviceLocator}  );
    
    return 0;
}

 sub getServiceName {
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_SERVICE_NAME)};
}

sub setServiceName {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(LS_KEY_SERVICE_NAME), value=>$value  );
    
}

sub getServiceType{
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_SERVICE_TYPE)};
}

sub setServiceType {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(LS_KEY_SERVICE_TYPE), value=>$value  );
    
}

sub getServiceVersion{
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_SERVICE_VERSION)};
}

sub setServiceVersion {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(LS_KEY_SERVICE_VERSION), value=>$value  );
    
}  
    
sub getServiceLocator{
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_SERVICE_LOCATOR)};
}

sub setServiceLocator {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(LS_KEY_SERVICE_LOCATOR), value=>$value  );
    
}   

sub getServiceAdministrators{
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_SERVICE_ADMINISTRATORS)};
}

sub setServiceAdministrators{
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(LS_KEY_SERVICE_ADMINISTRATORS), value=>$value  );
    
}   
    
sub getServiceDomains{
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_GROUP_DOMAINS)};
}

sub setServiceDomains {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(LS_KEY_GROUP_DOMAINS), value=>$value  );
    
}

sub getServiceLocationSiteName{
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_LOCATION_SITENAME)};
}

sub setServiceLocationSiteName {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(LS_KEY_LOCATION_SITENAME), value=>$value  );
    
}    

sub getServiceLocationCity{
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_LOCATION_CITY)};
}

sub setServiceLocationCity {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(LS_KEY_LOCATION_CITY), value=>$value  );
    
}

sub getServiceLocationState{
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_LOCATION_STATE)};
}

sub setServiceLocationState {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(LS_KEY_LOCATION_STATE), value=>$value  );
    
}

sub getServiceLocationCountry{
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_LOCATION_COUNTRY)};
}

sub setServiceLocationCountry {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(LS_KEY_LOCATION_COUNTRY), value=>$value  );
    
}

sub getServiceLocationZipCode{
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_LOCATION_CODE)};
}

sub setServiceLocationZipCode {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(LS_KEY_LOCATION_CODE), value=>$value  );
    
}

sub getServiceLatitude{
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_LOCATION_LATITUDE)};
}

sub setServiceLatitude {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(LS_KEY_LOCATION_LATITUDE), value=>$value  );
    
}

sub getServiceLongitude{
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_LOCATION_LONGITUDE)};
}

sub setServiceLongitude {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(LS_KEY_LOCATION_LONGITUDE), value=>$value  );
    
}
1;