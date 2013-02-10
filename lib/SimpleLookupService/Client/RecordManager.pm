package SimpleLookupService::Client::RecordManager;

=head1 NAME

SimpleLookupService::Client::RecordManager - The Lookup Service RecordManager class

=head1 DESCRIPTION

A class to manage/edit Lookup Service records. 

=cut

use strict;
use warnings;
use Scalar::Util qw(blessed);

our $VERSION = 3.3;

use Params::Validate qw( :all );
use JSON qw(encode_json decode_json);
use SimpleLookupService::Keywords::KeyNames;
use SimpleLookupService::Records::Record;
use SimpleLookupService::Records::RecordFactory;
use SimpleLookupService::Keywords::RecordTypeMapping;
use Data::Dumper;
use Carp qw(cluck);

use SimpleLookupService::Client::SimpleLS;

use fields 'INSTANCE', 'LOGGER', 'SERVER', 'RECORDURI', 'RECORD';


sub new {
    my $package = shift;
   
    my $self = fields::new( $package );
   
    return $self;
}

sub init  {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { server => 1, record_id => 0} );
    
    my $res;
    my $data;
    
    my $server = $parameters{server};
    if(! $server->isa('SimpleLookupService::Client::SimpleLS')){
    	cluck "Error initializing client. Server is not SimpleLookupService::Client::SimpleLS server";
    	return -1;
    }
    
    $self->{SERVER} = $server;
    $self->{SERVER}->connect();
    
    
    
    if (defined $parameters{'record_id'}){
    	$self->{RECORDURI}= $parameters{'record_id'};
    	
    }    
    
    return 0;
    
}


sub renew{
	
	my ($self, $ttl) = @_;
	if (defined $ttl){
		my $record = SimpleLookupService::Records::Network::Record->new();
		$record->init(ttl=>$ttl);
    	$self->_setRecord($record);
    }
	$self->{SERVER}->setConnectionType('POST');
	my $result = $self->{SERVER}->send(resourceLocator => $self->{RECORDURI});
	 if ($result->is_success) {
        my $jsonResp = decode_json($result->content);
        my $rType = $jsonResp->{'type'}->[0];
        my $resultRecord = SimpleLookupService::Records::RecordFactory->instantiate($rType);
        $resultRecord->fromHashRef($jsonResp);
		return (0, $resultRecord);
        #print $result->content;
        #return (0, $jsonResp);
    } else {
        return (-1, { message => $result->status_line });
    }
}



sub delete{
	my $self = shift;
	$self->{SERVER}->setConnectionType('DELETE');
	my $result = $self->{SERVER}->send(resourceLocator => $self->{RECORDURI});
	 if ($result->is_success) {
        my $jsonResp = decode_json($result->content);
        my $rType = $jsonResp->{'type'}->[0];
        my $resultRecord = SimpleLookupService::Records::RecordFactory->instantiate($rType);
        $resultRecord->fromHashRef($jsonResp);
		return (0, $resultRecord);
    } else {
        return (-1, { message => $result->status_line });
    }
}

sub getRecord{
	my $self = shift;
	$self->{SERVER}->setConnectionType('GET');
	my $result = $self->{SERVER}->send(resourceLocator => $self->{RECORDURI});
	 if ($result->is_success) {
        my $jsonResp = decode_json($result->content);
        my $rType = $jsonResp->{'type'}->[0];
        my $resultRecord = SimpleLookupService::Records::RecordFactory->instantiate($rType);
        $resultRecord->fromHashRef($jsonResp);
		return (0, $resultRecord);
    } else {
        return (-1, { message => $result->status_line });
    }
}


sub getKeyInRecord{
	
	my ($self, $key) = @_;
    
    if(defined $key){
    	my $modifiedUrl = $self->{RECORDURI};
    	$modifiedUrl .= "/".$key;
    	$self->{SERVER}->setConnectionType('GET');
		my $result = $self->{SERVER}->send(resourceLocator => $modifiedUrl);
		
	 	if ($result->is_success) {
        	my $jsonResp = decode_json($result->content);
        	
        	my $returnVal = $jsonResp->{$key};
        	if(defined $returnVal){
        		return (0, {$key => $returnVal});
        	}else{
        		return (-1, { message => $jsonResp});
        	}
   	 	}
    }else{
    	return (-1, { message => "key not defined"});
    }
   
}


sub _setRecord{
	my ($self, $record) = @_;
	if($record->isa('SimpleLookupService::Records::Record')){
		#check if record type is set
		my $type = $record->getRecordType();
		if(!defined $type){
			cluck "Record should contain record-type";
			return -1;
		}
		$self->{RECORD} = $record;
	}else{
		cluck "Record should be of type SimpleLookupService::Records::Record or its subclass ";
		return -1;
		
	}
	
	return 0;
	
}
