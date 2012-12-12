package SimpleLookupService::QueryObjects::QueryObject;

=head1 NAME

SimpleLookupService::QueryObjects::QueryObject - The base class for Lookup Service Records

=head1 DESCRIPTION

A base class for Lookup Service records. It defines the fields used by all 
records. service,interface, host and person records are direct subclasses of this class. It 
allows for any key to be added with the addField function.

=cut

use strict;
use warnings;

our $VERSION = 3.2;

use Params::Validate qw( :all );
use JSON qw(encode_json decode_json);
use SimpleLookupService::Keywords::KeyNames;

use fields 'RECORD_HASH', 'URLPARAMETERS';

sub new{
    my $package = shift;

    my $self = fields::new( $package );
   
    return $self;
}

sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { type => 0 } );
    
    if(defined $parameters{type}){
    	if (ref($parameters{type}) eq 'ARRAY'){
    		$parameters{type} = [ $parameters{type}[0]];
    	}else{
    		$parameters{type} = [$parameters{type}];
    	}
    } 
    $self->{RECORD_HASH} = {
            (SimpleLookupService::Keywords::KeyNames::LS_KEY_TYPE) => $parameters{type}
    }; 
    return 0;
}

sub create{
	my ( $self, @args ) = @_;
    my %parameters = validate( @args, { type => 0, uri=>0, expires=>0, ttl=>0 } );
    
    if(defined $parameters{type}){
    	if (ref($parameters{type}) eq 'ARRAY'){
    		$parameters{type} = [ $parameters{type}[0]];
    	}else{
    		$parameters{type} = [$parameters{type}];
    	}
    } 
    $self->{RECORD_HASH} = {
            (SimpleLookupService::Keywords::KeyNames::LS_KEY_TYPE) => $parameters{type}
    };
    
    if(defined $parameters{expires}){
    	if(ref($parameters{expires}) eq 'ARRAY'){
    		$parameters{expires} = [ $parameters{expires}[0]];
    	}else{
    		$parameters{expires} = [$parameters{expires}];
    	}
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)} = $parameters{expires};
    } 
    
    if(defined $parameters{uri}){
    	if(ref($parameters{uri}) eq 'ARRAY'){
    		$parameters{uri} = [ $parameters{uri}[0]];
    	}else{
    		$parameters{uri} = [$parameters{uri}];
    	}
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)} = $parameters{uri};
    }
    
    if(defined $parameters{ttl}){
    	if(ref($parameters{ttl}) eq 'ARRAY'){
    		$parameters{ttl} = [ $parameters{ttl}[0]];
    	}else{
    		$parameters{ttl} = [$parameters{ttl}];
    	}
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = $parameters{ttl};
    }  
    
    $self->{URLPARAMETERS} = toURLParameters();
   
    return ;
}

sub _makeArray {
    my ($self, $var) = @_;
  
    unless(ref($var) eq 'ARRAY'){
        $self->{INSTANCE} = [ $self->{INSTANCE} ];
    }
}

sub _convertToArray {
    my ($self, $var) = @_;
  	my $result ='';
    if(ref($var) eq 'ARRAY'){
    	my $totalCount = scalar @{$var};
    	my $curCount = 0;
        foreach my $elem (@{$var}){
        	if($curCount >= $totalCount-1){
        		$result .= $elem;
        	}else{
        		$result .= $elem . ",";
        	}
        	$curCount++;
        }
    }
}

sub addField {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { key => 1, value => 1 } );
    unless(ref($parameters{value}) eq 'ARRAY'){
    	$parameters{value} = [$parameters{value}];
    }
    $self->{RECORD_HASH}->{$parameters{key}} = $parameters{value}; 
}

sub getValue {
    my ( $self, $key ) = @_;
    
    if(defined $self->{RECORD_HASH}->{$key}){
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
    
    if(ref($value) eq 'ARRAY'){
    	$value = [$value->[0]];
    }
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TYPE)} = $value;
}

sub getRecordUri {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)};
}

sub setRecordUri {
    my ( $self, $value ) = @_;
    if(ref($value) eq 'ARRAY'){
    	$value = [$value->[0]];
    }
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)} = $value;
}

sub getRecordTtl {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)};
}

sub setRecordTtl {
    my ( $self, $value ) = @_;
    if(ref($value) eq 'ARRAY'){
    	$value = [$value->[0]];
    }
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = $value;
}

sub getRecordExpires {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)};
}

sub setRecordExpires {
    my ( $self, $value ) = @_;
    if(ref($value) eq 'ARRAY'){
    	$value = [$value->[0]];
    }
   $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)} = $value;
}

sub toURLParameters {
	my $self = shift;
	my $paramString = '?';
	my %recordHash = %{$self->{RECORD_HASH}};
	my $keysCount = keys %recordHash;
	my $curCount = 1;
	foreach my $key (keys %recordHash){
		if($curCount >= $keysCount){
			$paramString .= $key."=". _convertToArray($recordHash{$key})."&";
		}else{
			$paramString .= $key."=". _convertToArray($recordHash{$key});
		}		
	}
	return $paramString;
}

sub toJson{
	my $self = shift;
	return encode_json($self->getRecordHash());
}

sub fromJson{
	my ($self, $jsonData) = @_;
	my $perlDS = decode_json($jsonData);
	return $perlDS;
}

sub fromHashRef{
	my ($self, $perlDS) = @_;
	print "\n inside Record.pm...\n";
	
	foreach my $key (keys %{$perlDS}){
		$self->{RECORD_HASH}->{$key} = ${perlDS}->{$key};
	}
	return;
}
