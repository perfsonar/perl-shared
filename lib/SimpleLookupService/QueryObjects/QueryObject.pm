package SimpleLookupService::QueryObjects::QueryObject;

=head1 NAME

SimpleLookupService::QueryObjects::QueryObject - The base class for Query Object

=head1 DESCRIPTION

The base class for Query Object

=cut

use strict;
use warnings;

our $VERSION = 3.2;

use Params::Validate qw( :all );
use JSON qw(encode_json decode_json);
use SimpleLookupService::Keywords::KeyNames;
use Carp qw(cluck);

use fields 'RECORD_HASH', 'URLPARAMETERS';

sub new{
    my $package = shift;

    my $self = fields::new( $package );
   
    return $self;
}

sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { type => 0, uri=>0, expires=>0, ttl=>0 } );
    
    
    if(defined $parameters{type}){
    	my $res = $self->setRecordType($parameters{type});
    	
    	if($res != 0){
    		cluck "Error initializing QueryObject";
    		return $res;
    	}
    }
    
    
    if(defined $parameters{expires}){
    	
    	my $res = $self->setRecordExpires($parameters{expires});
    	if($res != 0){
    		cluck "Error initializing QueryObject";
    		return $res;
    	}
    	
    } 
    
    if(defined $parameters{uri} ){
    	
    	my $res = $self->setRecordUri($parameters{uri});
    	if($res != 0){
    		cluck "Error initializing QueryObject";
    		return $res;
    	}
    }
    
    if(defined $parameters{ttl}){
    	
    	my $res = $self->setRecordTtl($parameters{ttl});
    	if($res != 0){
    		cluck "Error initializing QueryObject";
    		return $res;
    	}
    	
    }
     
    return 0;
}

sub _makeArray {
    my ($self, $var) = @_;
  
    unless(ref($var) eq 'ARRAY'){
        $self->{INSTANCE} = [ $self->{INSTANCE} ];
    }
}

sub _convertToURLArray {
    my ($self, $var) = @_;
  	my $result ='';
  	
  	if(!defined $var){
  		return $result;
  	}
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
    }else{
    	$result = $var;
    }
    
    return $result;
}

sub addField {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { key => 1, value => 1 } );
    
    unless(ref($parameters{value}) eq 'ARRAY'){
    	$parameters{value} = [$parameters{value}];
    }
    $self->{RECORD_HASH}->{$parameters{key}} = $parameters{value}; 
    
    return 0;
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
    
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TYPE)} = $value;
    
    return 0;
}

sub getRecordUri {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)};
}

sub setRecordUri {
    my ( $self, $value ) = @_;
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)} = $value;
    
    return 0;
}

sub getRecordTtl {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)};
}

sub setRecordTtl {
    my ( $self, $value ) = @_;
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = $value;
    
    return 0;
}

sub getRecordExpires {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)};
}

sub setRecordExpires {
    my ( $self, $value ) = @_;
    unless(ref($value) eq 'ARRAY'){
    	$value = [$value];
    }
   $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)} = $value;
   return 0;
}


sub setKeyOperator{
	my ( $self, @args ) = @_;
    my %parameters = validate( @args, { key => 1, operator => 1 } );
    
    if (defined $self->{RECORD_HASH}->{$parameters{key}}){
    	
    	if($parameters{operator} =~ m/all|any/i){
    		my $key = $parameters{key};
    		$key .= SimpleLookupService::Keywords::KeyNames::LS_KEY_OPERATOR_SUFFIX;
    		$self->addField({key=>$key, value=>$parameters{operator}});
    	}else{
    		cluck "Operator should be ALL or ANY";
    		return -1;
    	}
    	
    	
    }else {
    	cluck "Setting operator for a non-existent key";
    	return -1;
    }

    return 0;
	
}


sub getKeyOperator{
	my ( $self, $value ) = @_;
    if(ref($value) eq 'ARRAY' && scalar(@{$value}) > 1){
    	cluck "Key array size cannot be > 1";
    	return -1;
    }
    
    my $key = '';
    if(ref($value) eq 'ARRAY'){
    	$key = $value->[0];
    }else{
    	$key = $value;
    }
    
    if (defined $self->{RECORD_HASH}->{$key}){  	
    	if($key =~ m/all|any/i){
    		my $opkey = $key.(SimpleLookupService::Keywords::KeyNames::LS_KEY_OPERATOR_SUFFIX);
    		return $self->getValue($opkey);
    	}else{
    		cluck "Operator should be ALL or ANY";
    		return -1;
    	}
    }else{
    	cluck "Getting operator for a non-existent key";
    	return -1;
    }

    return 0;
	
}


sub setOperator{
	my ( $self, $value ) = @_;
    
    
    if(ref($value) eq 'ARRAY' && scalar(@{$value}) > 1){
    	cluck "Record Type array size cannot be > 1";
    	return -1;
    }
    
    my $op = '';
    if(ref($value) eq 'ARRAY'){
    	$op = $value->[0];
    }else{
    	$op = $value;
    }
    
    if($op =~ m/all|any/i){
    	return $self->addField(key=>(SimpleLookupService::Keywords::KeyNames::LS_KEY_OPERATOR), value=>[$op]);
    }else{
    	cluck "Operator should be ALL or ANY";
        return -1;
    }

}

sub getOperator{
	my $self = shift;
	return $self->getValue(SimpleLookupService::Keywords::KeyNames::LS_KEY_OPERATOR);
}

sub toURLParameters {
	my $self = shift;
	my $paramString = '?';
	
	if(defined $self->{RECORD_HASH}){
		my %recordHash = %{$self->{RECORD_HASH}};
		my $keysCount = keys %recordHash;
		my $curCount = 1;
		foreach my $key (keys %recordHash){
			my $val = '';
			
			$val = $self->{RECORD_HASH}->{$key};
			
			$paramString .= $key."=";
			$paramString .=  $self->_convertToURLArray($val);
			if($curCount < $keysCount){
				$paramString .= "&";
			}
		    $curCount++;		
		}
		return $paramString;
	}else{
		return '';
	}

}


sub fromHashRef{
	my ($self, $perlDS) = @_;
	
	foreach my $key (keys %{$perlDS}){
		$self->{RECORD_HASH}->{$key} = ${perlDS}->{$key};
	}
	return;
}
