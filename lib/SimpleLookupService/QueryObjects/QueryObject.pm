package SimpleLookupService::QueryObjects::QueryObject;

=head1 NAME

SimpleLookupService::QueryObjects::QueryObject - The base class for Query Object

=head1 DESCRIPTION

The base class for Query Object

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use Params::Validate qw( :all );
use JSON qw(encode_json decode_json);
use SimpleLookupService::Keywords::KeyNames;
use Carp qw(cluck);
use DateTime::Format::ISO8601;

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
    	my $res = $self->setRecordType($parameters{type});
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
    
    #aaray can be > 1
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
    
    #array can be > 1

	unless (ref($value) eq 'ARRAY'){
		$value  = [$value];
	}
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)} = $value;
    return 0;
}


sub getRecordTtlAsIso {
    my $self = shift;
    my $value = $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)};
    
    
    if(defined $value && ref($value) eq "ARRAY"){
    	my @outputArray;
    	foreach my $val (@{$value}){
    		if($self->_is_iso($val)){
	    		push @outputArray, $val;
	    	}else{
	    		my $tmp = $self->_minutes_to_iso($val);
	    		push @outputArray, $tmp;
	    	}
    	}
    	return \@outputArray;
	    
    }elsif(defined $value){
    	 if($self->_is_iso($value)){
	    		return [$value];
	    	
	    	}else{
	    		my $tmp = $self->_minutes_to_iso($value);
	
	    		return [$tmp];
	    }
    }
    
    return undef;
    
}


sub setRecordTtlAsIso {
    my ( $self, $value ) = @_;
    
    my $ttl = 0;
    if(ref($value) eq 'ARRAY'){
    	my @array;
    	foreach my $val (@{$value}){
    		$ttl = $val;
    		if($self->_is_iso($ttl)){
    			push @array, $ttl;
    		}else{
    			cluck "Record Ttl not in ISO 8601 format";
    			return -1;
    		}
    		$ttl=undef;
    		  
    	}
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = \@array;
    }else{
    	$ttl = $value;
    	if($self->_is_iso($ttl)){
    			$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = [$ttl];
    	}else{
    		cluck "Record Ttl not in ISO 8601 format";
    		return -1;
    	}
    }   
    
    return 0;
}


sub getRecordTtlInMinutes {
    my $self = shift;
    my $value = $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)};
    
    
    if(defined $value && ref($value) eq "ARRAY"){
    	my @outputArray;
    	foreach my $val (@{$value}){
    		if(!$self->_is_iso($val)){
	    		push @outputArray, $val;
	    	}else{
	    		my $tmp = $self->_iso_to_minutes($val);
	    		push @outputArray, $tmp;
	    	}
    	}
    	return \@outputArray;
	    
    }elsif(defined $value){
    	 if(!$self->_is_iso($value)){
	    		return [$value];
	    	
	    	}else{
	    		my $tmp = $self->_iso_to_minutes($value);
	
	    		return [$tmp];
	    }
    }
    
    return undef;
    
}


sub setRecordTtlInMinutes {
    my ( $self, $value ) = @_;
    
    my $ttl = 0;
    if(ref($value) eq 'ARRAY'){
    	my @array;
    	foreach my $val (@{$value}){
    		$ttl = $val;
    		if(!$self->_is_iso($ttl)){
    			push @array, $ttl;
    		}else{
    			cluck "Record Ttl is not in minutes";
    			return -1;
    		}
    		$ttl=undef;
    		  
    	}
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = \@array;
    }else{
    	$ttl = $value;
    	if(!$self->_is_iso($ttl)){
    			$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = [$ttl];
    	}else{
    		cluck "Record Ttl not in minutes";
    		return -1;
    	}
    }   
    
    return 0;
}


sub getRecordExpiresAsUnixTS {
    my $self = shift;
    my $expires = $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)};
    
    my @unixTSarray;
    if(defined $expires && scalar @{$expires}>0){
    	foreach my $expire (@{$expires}){
    		my $unixts = $self->_isoToUnix($expire);
    		push(@unixTSarray, $unixts);
    		$unixts=undef;
    	}
    }
    
    
    if (@unixTSarray){
    	
    	return \@unixTSarray;
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
    

	unless (ref($value) eq 'ARRAY'){
		$value  = [$value];
	}
	
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)} = $value;
    return 0;
}



sub setKeyOperator{
	my ( $self, @args ) = @_;
    my %parameters = validate( @args, { key => 1, operator => 1 } );
    
    if(ref($parameters{'key'}) eq 'ARRAY' && scalar(@{$parameters{'key'}}) > 1){
    	cluck "Only one key allowed";
    	return -1;
    }
    
    if(ref($parameters{operator}) eq 'ARRAY' && scalar(@{$parameters{'operator'}}) > 1){
    	cluck "Only one operator allowed";
    	return -1;
    }
    
    my $key;
    if(ref($parameters{'key'}) eq 'ARRAY'){
    	$key = $parameters{key}->[0];
    }else{
    	$key = $parameters{key};
    }
    
    
    my $value;
    if(ref($parameters{'operator'}) eq 'ARRAY'){
    	$value = $parameters{'operator'}->[0];
    }else{
    	$value = $parameters{'operator'};
    }
    if (defined $self->{RECORD_HASH}->{$key}){
    	
    	if($value =~ m/all|any/i){
    		my $tmpkey = $key;
    		$tmpkey .= SimpleLookupService::Keywords::KeyNames::LS_KEY_OPERATOR_SUFFIX;
    		$self->addField({key=>$tmpkey, value=>$parameters{operator}});
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
    	my $opkey = $key.(SimpleLookupService::Keywords::KeyNames::LS_KEY_OPERATOR_SUFFIX);
    	print $opkey;
    	return $self->getValue($opkey);
    
    }else{
    	cluck "Getting operator for a non-existent key";
    	return -1;
    }

    return 0;
	
}


sub setOperator{
	my ( $self, $value ) = @_;
    
    
    if(ref($value) eq 'ARRAY' && scalar(@{$value}) > 1){
    	cluck "Only one operator allowed";
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


#creates record object from perl data structure
sub fromHashRef(){
	my ($self, $perlDS) = @_;
	
	if(defined $perlDS){
		foreach my $key (keys %{$perlDS}){
			$self->{RECORD_HASH}->{$key} = ${perlDS}->{$key};
		}
	}else{
		cluck "Error creating record. Empty hash";
		return -1;
	}
	
	
	return 0;
}


sub _is_iso{
	my ($self, $value) = @_;
	
	($value =~ m/P\w*T/)?return 1: return 0;
}

sub _minutes_to_iso{
	my ($self, $ttl) = @_;
    
    if(defined $ttl && $ttl eq ''){
    	cluck "Empty ttl";
    	return undef;
    }
    
    my $isottl;
   
    if($ttl =~ m/P\w*T/){
    	cluck "Found iso format";
    	return undef;
    }
    $isottl = "PT". $ttl ."M";
    
    return $isottl;
}

sub _iso_to_minutes{
	my ($self, $value) = @_;
	
	if(!defined $value){
		return undef;
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
	
	($minutes>0)?return int($minutes+0.5):return undef;	
	
}


=head2 _isoToUnix($self { uri, base})

Converts a given ISO 8601 date string to a unix timestamp

=cut
sub _isoToUnix {
    my ($self, $str) = @_;
    my $dt = DateTime::Format::ISO8601->parse_datetime($str);
    return $dt->epoch();
}
