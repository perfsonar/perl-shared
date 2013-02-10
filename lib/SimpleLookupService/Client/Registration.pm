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

use fields 'INSTANCE', 'LOGGER', 'SERVER', 'RECORD';


sub new {
    my $package = shift;
   
    my $self = fields::new( $package );
   
    return $self;
}

sub init  {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { server => 1, record => 0} );
    
    my $res;
    my $data;
    
    my $server = $parameters{server};
    if(! $server->isa('SimpleLookupService::Client::SimpleLS')){
    	cluck "Error initializing client. Server is not SimpleLookupService::Client::SimpleLS server";
    	return -1;
    }
    
    $self->{SERVER} = $server;
    $self->{SERVER}->connect();
    
    $self->{SERVER}->setConnectionType('POST');
    
    
    
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
    
    
    if(!defined $self->{RECORD}){
    	cluck "Record not defined";
    	return -1;
    }
    
    my $res = $self->{SERVER}->setData($self->{RECORD}->toJson());
    
    if($res<0){
    	cluck "Error setting data";
    	return -1;
    }
    
    my $result = $self->{SERVER}->send(resourceLocator=>"lookup/records");
    
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
		$self->{RECORD} = $record;
	}else{
		cluck "Record should be of type SimpleLookupService::Records::Record or its subclass ";
		return -1;
		
	}
	
	return 0;
	
}
