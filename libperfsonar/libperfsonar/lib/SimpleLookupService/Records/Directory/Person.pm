package SimpleLookupService::Records::Directory::Person;

=head1 NAME

SimpleLookupService::Records::Directory::Person - User records

=head1 DESCRIPTION

A base class for user records. it is used to store contact details

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use base 'SimpleLookupService::Records::Record';

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use Carp qw(cluck);

use SimpleLookupService::Keywords::Values;
use SimpleLookupService::Keywords::KeyNames;

sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { personName => 1, emails => 1, 
    									phoneNumbers => 0, organization => 0,
    									siteName => 0 , city => 0, region => 0,
    									country => 0, zipCode => 0, latitude =>0, longitude => 0  } );
    
    $self->SUPER::init(type=>(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_PERSON)); 
    
     if(defined $parameters{personName}){
    	my $ret = $self->setPersonName($parameters{personName});
    	if($ret <0){
    		cluck "Error initializing Service record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{emails}){
    	my $ret = $self->setEmailAddresses($parameters{emails});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{phoneNumbers}){
    	my $ret = $self->setPhoneNumbers($parameters{phoneNumbers});
    	if($ret <0){
    		cluck "Error initializing Host record";
    		return $ret;
    	}
    }
    
    if(defined $parameters{organization}){
    	my $ret = $self->setOrganization($parameters{organization});
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

sub getPersonName {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_PERSON_NAME)};
}

sub setPersonName {
    my ( $self, $value ) = @_;
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_PERSON_NAME), value=>$value  );
    
}

sub getEmailAddresses {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_PERSON_EMAILS)};
}

sub setEmailAddresses {
    my ( $self, $value ) = @_;
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_PERSON_EMAILS), value=>$value  );
    
}

sub getPhoneNumbers {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_PERSON_PHONENUMBERS)};
}

sub setPhoneNumbers {
    my ( $self, $value ) = @_;
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_PERSON_PHONENUMBERS), value=>$value  );
    
}

sub getOrganization {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_PERSON_ORGANIZATION)};
}

sub setOrganization {
    my ( $self, $value ) = @_;
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    return $self->SUPER::addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_PERSON_ORGANIZATION), value=>$value  );
    
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
