package SimpleLookupService::Client::Registration;

=head1 NAME

SimpleLookupService::Client::Registration - The Lookup Service Registration class

=head1 DESCRIPTION

A base class for Lookup Service registrations. It defines the fields used by all 
registrations. Specific types of service records may become subclasses of this class. It 
allows for any key to be added with the addField function.

=cut

use strict;
use warnings;
use Scalar::Util qw(blessed);

our $VERSION = 3.2;

use Params::Validate qw( :all );
use JSON qw(encode_json decode_json);
use SimpleLookupService::Keywords::KeyNames;
use SimpleLookupService::Records::Record;
use SimpleLookupService::Records::RecordFactory;
use SimpleLookupService::Keywords::RecordTypeMapping;
use Data::Dumper;
use Carp qw(cluck);

use base 'SimpleLookupService::Client::SimpleLS';

sub init  {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { LS => 1, record => 1} );
    
    my $res;
    my $data;
    if(defined $parameters{'timeout'}){
    	$res =  $self->SUPER::init({
           url => $parameters{'url'},
           timeout => $parameters{'timeout'},
           connectionType => 'POST'
    	});
    }else{
    	$res = $self->SUPER::init({
           url => $parameters{'url'},
           connectionType => 'POST'
    	});
    }
    
    if($res != 0){
    	cluck "Error initializing client";
    	return -1;
    }
    
    if (defined $parameters{'record'}){
    	my $r = $self->_setRecord($parameters{'record'});
    	if($r != 0){
    		cluck "Error initializing client. Record could not be set.";
    		return -1;
    	}
    }    
    
    return 0;
    
}

sub register{
	my ($self, $parameter) = @_;
	#print Dumper $self;
    if (defined $parameter){
    	
    	$self->_setRecord($parameter);
    }
    
    if(!defined $self->{DATA}){
    	cluck "Record not defined";
    	return -1;
    }
    
    my $result = $self->SUPER::connect();
    
        # Check the outcome of the response
    if ($result->is_success) {
        my $jsonResp = decode_json($result->content);
        #print $jsonResp;
        my $rType = $jsonResp->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TYPE)}->[0];
        my $resultRecord = SimpleLookupService::Records::RecordFactory->instantiate($rType);
        $resultRecord->fromHashRef($jsonResp);
		return (0, $resultRecord);
    } else {
        return (-1, { message => $result->status_line });
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
		my $data = $record->toJson();
		$self->SUPER::setData({data => $data});
	}else{
		cluck "Record should be of type SimpleLookupService::Records::Record or its subclass ";
		return -1;
		
	}
	
	return 0;
	
}

1;