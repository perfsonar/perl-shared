package SimpleLookupService::Records::Record;

=head1 NAME

SimpleLookupService::Records::Record - The base class for Lookup Service Records

=head1 DESCRIPTION

A base class for Lookup Service records. It defines the fields used by all 
records. service,interface, host and person records are direct subclasses of this class. It 
allows for any key to be added with the addField function.

ttl - specified in minutes (max - 43200 minutes (30 days))

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use Params::Validate qw( :all );

use SimpleLookupService::Keywords::KeyNames;
use DateTime::Format::ISO8601;
use Carp qw(cluck);

use SimpleLookupService::Utils::Time qw(minutes_to_iso iso_to_minutes is_iso iso_to_unix);

use base 'SimpleLookupService::Message';

sub new {
    my $package = shift;

    my $self = fields::new( $package );
   
    return $self;
}

sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { type => 1, uri=>0, expires=>0, ttl=>0, client_uuid=>0 } );
    
    if(ref($parameters{type}) eq 'ARRAY' && scalar @{$parameters{type}} > 1){
    	cluck "Record Type array size cannot be > 1";
    	return -1;
    }
    
    unless(ref($parameters{type}) eq 'ARRAY'){
    		$parameters{type} = [$parameters{type}];
    }
    
    $self->{RECORD_HASH} = {
            (SimpleLookupService::Keywords::KeyNames::LS_KEY_TYPE) => $parameters{type}
    }; 
    
    if(defined $parameters{expires}){
    	if(ref($parameters{expires}) eq 'ARRAY' && scalar @{$parameters{expires}} > 1){
    		cluck "Expires array size cannot be > 1";
    		return -1;
    	}
    	
    	unless(ref($parameters{expires}) eq 'ARRAY'){
    		$parameters{expires} = [$parameters{expires}];
    	}
    	
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)} = $parameters{expires};
    } 
    
    if(defined $parameters{uri} ){
    	if(ref($parameters{uri}) eq 'ARRAY' && scalar @{$parameters{uri}} > 1){
    		cluck "Record URI size cannot be > 1";
    		return -1;                                           
    	}
    	
    	unless(ref($parameters{uri}) eq 'ARRAY'){
    		$parameters{uri} = [$parameters{uri}];
    	}
    	
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)} = $parameters{uri};
    }
    
    if(defined $parameters{ttl}){
    	
    	if(ref($parameters{ttl}) eq 'ARRAY' && scalar @{$parameters{ttl}} > 1){
    		cluck "Record TTL size cannot be > 1";
    		return -1;
    	}
    	my $tmp;
    	if(ref($parameters{ttl}) eq 'ARRAY'){
    		$tmp = $parameters{ttl}->[0];
    	}else{
    		$tmp = $parameters{ttl};
    	}
    	
    	if(is_iso($tmp)){
    		$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = [$tmp];
    	}else{
    		cluck "Record TTL should be iso";
    		return -1;
    	}
    	
    } 
    
    if(defined $parameters{client_uuid} ){
    	unless(ref($parameters{client_uuid}) eq 'ARRAY'){
    		$parameters{client_uuid} = [$parameters{client_uuid}];
    	}
    	
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_CLIENT_UUID)} = $parameters{client_uuid};
    }
     
    return 0;
}

sub addField {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { key => 1, value => 1 } );
    
    if(ref($parameters{key}) eq 'ARRAY'){
    	cluck "Lookup Service Key cannot be an array";
    	return -1;
    }
    unless(ref($parameters{value}) eq 'ARRAY'){
    	$parameters{value} = [$parameters{value}];
    }
    $self->{RECORD_HASH}->{$parameters{key}} = $parameters{value}; 
    return 0;
}

sub getValue {
    my ( $self, $key ) = @_;
    
    if(defined $self->{RECORD_HASH}->{$key}){
    	unless(ref($self->{RECORD_HASH}->{$key}) eq 'ARRAY'){
    		return [$self->{RECORD_HASH}->{$key}];
    	}
    	return $self->{RECORD_HASH}->{$key};
    }else{
    	return (undef) ;
    }
    
}



sub getRecordType {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TYPE)};
}

sub setRecordType {
    my ( $self, $value ) = @_;
    if(ref($value) eq 'ARRAY' && scalar(@{$value}) > 1){
    	cluck "Record Type array size cannot be > 1";
    	return -1;
    }
    
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    	   
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TYPE)} = $value;
    return 0;
}

sub getRecordTtlAsIso {
    my $self = shift;
    my $value = $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)}->[0];
    
    if(defined $value){
	    if(is_iso($value)){
	    	return [$value];
	    	
	    }else{
	    	my $tmp = minutes_to_iso($value);
	
	    	return [$tmp];
	    }
    }
    
    return undef;
    
}

sub setRecordTtlAsIso {
    my ( $self, $value ) = @_;
    
    if(ref($value) eq 'ARRAY' && scalar(@{$value}) > 1){
    	cluck "Record Ttl array size cannot be > 1";
    	return -1;
    }
    
    my $ttl = 0;
    if(ref($value) eq 'ARRAY'){
    	$ttl = $value->[0];
    }else{
    	$ttl = $value;
    }
    
    if(is_iso($ttl)){
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = [$ttl];
    }else{
    	cluck "Record Ttl not in ISO 8601 format";
    	return -1;
    }  
    
    return 0;
}

sub getRecordTtlInMinutes {
    my $self = shift;
    my $value = $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)}->[0];
    
    if(defined $value){
	    if(is_iso($value)){
	    	my $tmp = iso_to_minutes($value);
	
	    	return [$tmp];
	    }else{
	    	return [$value];
	    }
    }
    
    return undef;
    
}


sub setRecordTtlInMinutes {
    my ( $self, $value ) = @_;
    
    if(ref($value) eq 'ARRAY' && scalar(@{$value}) > 1){
    	cluck "Record Ttl array size cannot be > 1";
    	return -1;
    }
    
    my $ttl = 0;
    if(ref($value) eq 'ARRAY'){
    	$ttl = $value->[0];
    }else{
    	$ttl = $value;
    }
    
    if(is_iso($ttl)){
    	cluck "Record Ttl should be in minutes (integer)";
    	return -1;
    }else{
    	
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = [minutes_to_iso($ttl)];
    }  
    
    return 0;
}


sub getRecordExpiresAsUnixTS {
    my $self = shift;
    my $expires = $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)};
    
    if (defined $expires){
    	my $unixts = iso_to_unix($expires->[0]);
    	return [$unixts];
    }else{
    	return undef;
    }
   
}

sub getRecordExpires {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)};
   
}

sub setRecordExpires {
    my ( $self, $value ) = @_;
    
    if(ref($value) eq 'ARRAY' && scalar(@{$value}) > 1){
    	cluck "Record Type array size cannot be > 1";
    	return -1;
    }

	unless (ref($value) eq 'ARRAY'){
		$value  = [$value];
	}
	
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)} = $value;
    return 0;
}

sub getRecordUri {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)};
}

sub setRecordUri {
    my ( $self, $value ) = @_;
        if(ref($value) eq 'ARRAY' && scalar(@{$value}) > 1){
    	cluck "Record Type array size cannot be > 1";
    	return -1;
    }

	unless (ref($value) eq 'ARRAY'){
		$value  = [$value];
	}
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)} = $value;
    return 0;
}

sub getRecordClientUUID {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_CLIENT_UUID)};
}

sub setRecordClientUUID {
    my ( $self, $value ) = @_;

	unless (ref($value) eq 'ARRAY'){
		$value  = [$value];
	}
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_CLIENT_UUID)} = $value;
    return 0;
}


