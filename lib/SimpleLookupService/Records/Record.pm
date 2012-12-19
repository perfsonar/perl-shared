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

our $VERSION = 3.2;

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);
use SimpleLookupService::Keywords::KeyNames;
use DateTime::Format::ISO8601;
use Carp qw(cluck);

use fields 'RECORD_HASH';

use constant {
	RECORD_MAX_TTL => 43200,
	RECORD_DEFAULT_TTL => 120,
	RECORD_MIN_TTL => 30
};

sub new {
    my $package = shift;

    my $self = fields::new( $package );
   
    return $self;
}

sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { type => 1, uri=>0, expires=>0, ttl=>0 } );
    
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
    	
    	if($self->_is_iso($tmp)){
    		$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = [$tmp];
    	}else{
    		$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = [$self->_minutes_to_iso($tmp)];
    	}
    	
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

sub getRecordHash {
    my $self = shift;
    return $self->{RECORD_HASH};
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

sub getRecordTtl {
    my $self = shift;
    my $value = $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)}->[0];
    
    if(defined $value){
	    if($self->_is_iso($value)){
	    	my $tmp = $self->_iso_to_minutes($value);
	
	    	return [$tmp];
	    }else{
	    	return [$value];
	    }
    }
    
    return undef;
    
}

sub setRecordTtl {
    my ( $self, $value ) = @_;
    
    if(ref($value) eq 'ARRAY' && scalar(@{$value}) > 1){
    	cluck "Record Type array size cannot be > 1";
    	return -1;
    }
    
    my $ttl = 0;
    if(ref($value) eq 'ARRAY'){
    	$ttl = $value->[0];
    }else{
    	$ttl = $value;
    }
    
    if($self->_is_iso($ttl)){
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = [$ttl];
    }else{
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = [$self->_minutes_to_iso($ttl)];
    }  
    
    return 0;
}

sub getRecordExpires {
    my $self = shift;
    my $expires = $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)}->[0];
    
    if(defined $expires){
    	my $unixTS = $self->_isoToUnix($expires);
    	return [$unixTS];
    }
    
    return undef;
}

sub getRecordUri {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)};
}

sub toJson(){
	my $self = shift;
	
	if(defined $self->getRecordHash()){
		return encode_json($self->getRecordHash());
	}else{
		return undef;
	}
	
}

#creates record object from json
sub fromJson(){
	my ($self, $jsonData) = @_;
	my $perlDS = decode_json($jsonData);
	fromHashRef($perlDS);
}

#creates record object from perl data structure
sub fromHashRef(){
	my ($self, $perlDS) = @_;
	
	foreach my $key (keys %{$perlDS}){
		$self->{RECORD_HASH}->{$key} = ${perlDS}->{$key};
	}
}


sub _is_iso{
	my ($self, $value) = @_;
	
	($value =~ m/P\w*T/)?return 1: return 0;
}

sub _minutes_to_iso{
	my ($self, $ttl) = @_;
	
	unless($ttl >= (RECORD_MIN_TTL) && $ttl<= (RECORD_MAX_TTL)){
    	$ttl = RECORD_DEFAULT_TTL;
    }
    
    my $isottl;
    $isottl = "PT". $ttl ."M";
    
    return $isottl;
}

sub _iso_to_minutes{
	my ($self, $value) = @_;
	
	if(!defined $value){
		return -1;
	}
	my @splitDuration = split(/T/, $value);
	
	my %dHash = (
		   "Y" => 525600,
			"M" => 43200,
			"W"  => 10080,
			"D" => 1440);
			
	my %tHash = (
		   "H" => 60,
			"M" => 1,
			"S"  => 0.0167 );
			
	$splitDuration[0] =~ tr/P//d;
	
	my $minutes = 0;
	foreach my $key (keys %dHash){
			$splitDuration[0] =~ m/(\d+)$key/;
			 $minutes += $dHash{$key}*$1 if $1;
	}
	
	if(scalar @splitDuration ==2){
		
		foreach my $key (keys %tHash){
			$splitDuration[1] =~ m/(\d+)$key/;
			$minutes += $tHash{$key}*$1 if $1;
		}
	}
	
	($minutes>0)?return int($minutes+0.5):return -1;	
	
}


=head2 _isoToUnix($self { uri, base})

Converts a given ISO 8601 date string to a unix timestamp

=cut
sub _isoToUnix {
    my ($self, $str) = @_;
    my $dt = DateTime::Format::ISO8601->parse_datetime($str);
    return $dt->epoch();
}

#sub setRecordUri {
#    my ( $self, $value ) = @_;
#    if(ref($value) eq 'ARRAY'){
#    	$value = [$value->[0]];
#    }
#    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)} = $value;
#}

#sub setRecordExpires {
#    my ( $self, $value ) = @_;
#    if(ref($value) eq 'ARRAY'){
#    	$value = [$value->[0]];
#    }
#    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)} = $value;
#}