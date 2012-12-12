package SimpleLookupService::QueryObjects::Network::ServiceQueryObject;

=head1 NAME

SimpleLookupService::QueryObjects::Network::Service - Query Object for Network services

=head1 DESCRIPTION

Query Object for Network services

=cut

use strict;
use warnings;

our $VERSION = 3.2;

use base 'SimpleLookupService::QueryObjects::QueryObject';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use SimpleLookupService::Keywords::KeyNames;
use SimpleLookupService::Keywords::Values;


sub init {
    my ( $self, @args ) = @_;
    
    $self->SUPER::init(type=>(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_SERVICE)); 
    
    return $self;
}

 sub getServiceName {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_NAME)};
}

sub setServiceName {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_NAME), value=>$value  );
    
}

sub getServiceType{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_TYPE)};
}

sub setServiceType {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_TYPE), value=>$value  );
    
}

sub getServiceVersion{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_VERSION)};
}

sub setServiceVersion {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_VERSION), value=>$value  );
    
}  
    
sub getServiceLocator{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_LOCATOR)};
}

sub setServiceLocator {
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_LOCATOR), value=>$value  );
    
}   

sub getServiceAdministrators{
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_ADMINISTRATORS)};
}

sub setServiceAdministrators{
    my ( $self, $value ) = @_;
    $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_SERVICE_ADMINISTRATORS), value=>$value  );
    
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