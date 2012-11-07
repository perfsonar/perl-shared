package SimpleLookupService::Records::Record;

=head1 NAME

SimpleLookupService::Records::Record - The base class for Lookup Service Records

=head1 DESCRIPTION

A base class for Lookup Service records. It defines the fields used by all 
records. service,interface, host and person records are direct subclasses of this class. It 
allows for any key to be added with the addField function.

=cut

use strict;
use warnings;

our $VERSION = 3.2;

use Params::Validate qw( :all );
use JSON qw( encode_json decode_json);

use fields 'RECORD_HASH';

use constant {
    LS_KEY_TYPE => "type",
    LS_KEY_EXPIRES => "expires",
    LS_KEY_TTL => "ttl",
    LS_KEY_URI => "uri",
};

sub new {
    my $package = shift;

    my $self = fields::new( $package );
   
    return $self;
}

sub init {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { type => 1 } );
    
    if(ref($parameters{type}) eq 'ARRAY'){
    	$parameters{type} = [ $parameters{type}[0]];
    }else{
    	$parameters{type} = [$parameters{type}];
    }
    
    $self->{RECORD_HASH} = {
            (LS_KEY_TYPE) => $parameters{type}
    }; 
    return 0;
}

sub create{
	my ( $self, @args ) = @_;
    my %parameters = validate( @args, { type => 1, uri=>0, expires=>0, ttl=>0 } );
    
    if(ref($parameters{type}) eq 'ARRAY'){
    	$parameters{type} = [ $parameters{type}[0]];
    }else{
    	$parameters{type} = [$parameters{type}];
    }
     $self->{RECORD_HASH} = {
            (LS_KEY_TYPE) => $parameters{type}
    };
    
    if(defined $parameters{expires}){
    	if(ref($parameters{expires}) eq 'ARRAY'){
    		$parameters{expires} = [ $parameters{expires}[0]];
    	}else{
    		$parameters{expires} = [$parameters{expires}];
    	}
    	$self->{RECORD_HASH}->{(LS_KEY_EXPIRES)} = $parameters{expires};
    } 
    
    if(defined $parameters{uri}){
    	if(ref($parameters{uri}) eq 'ARRAY'){
    		$parameters{uri} = [ $parameters{uri}[0]];
    	}else{
    		$parameters{uri} = [$parameters{uri}];
    	}
    	$self->{RECORD_HASH}->{(LS_KEY_URI)} = $parameters{uri};
    }
    
    if(defined $parameters{ttl}){
    	if(ref($parameters{ttl}) eq 'ARRAY'){
    		$parameters{ttl} = [ $parameters{ttl}[0]];
    	}else{
    		$parameters{ttl} = [$parameters{ttl}];
    	}
    	$self->{RECORD_HASH}->{(LS_KEY_TTL)} = $parameters{ttl};
    }  
   
    return 0;
}

sub _makeArray {
    my ($self, $var) = @_;
  
    unless(ref($var) eq 'ARRAY'){
        $self->{INSTANCE} = [ $self->{INSTANCE} ];
    }
}

sub addField {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { key => 1, value => 1 } );
    
    $self->{RECORD_HASH}->{$parameters{key}} = $parameters{value}; 
}

sub getRecordHash {
    my $self = shift;
    return $self->{RECORD_HASH};
}

sub getRecordType {
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_TYPE)};
}

sub setRecordType {
    my ( $self, $value ) = @_;
    
    if(ref($value) eq 'ARRAY'){
    	$value = [$value->[0]];
    }
    $self->{RECORD_HASH}->{(LS_KEY_TYPE)} = $value;
}

sub getRecordUri {
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_URI)};
}

sub setRecordUri {
    my ( $self, $value ) = @_;
    if(ref($value) eq 'ARRAY'){
    	$value = [$value->[0]];
    }
    $self->{RECORD_HASH}->{(LS_KEY_URI)} = $value;
}

sub getRecordTtl {
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_TTL)};
}

sub setRecordTtl {
    my ( $self, $value ) = @_;
    if(ref($value) eq 'ARRAY'){
    	$value = [$value->[0]];
    }
    $self->{RECORD_HASH}->{(LS_KEY_TTL)} = $value;
}

sub getRecordExpires {
    my $self = shift;
    return $self->{RECORD_HASH}->{(LS_KEY_EXPIRES)};
}

sub setRecordExpires {
    my ( $self, $value ) = @_;
    if(ref($value) eq 'ARRAY'){
    	$value = [$value->[0]];
    }
   $self->{RECORD_HASH}->{(LS_KEY_EXPIRES)} = $value;
}


sub toJson(){
	my $self = shift;
	return encode_json($self->getRecordHash());
}
