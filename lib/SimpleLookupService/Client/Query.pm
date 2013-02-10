package SimpleLookupService::Client::Query;

=head1 NAME

SimpleLookupService::Client::Query - The Lookup Service Query class

=head1 DESCRIPTION

A base class for Lookup Service queries. It defines the fields used by all 
registrations. Specific types of service records may become subclasses of this class. It 
allows for any key to be added with the addField function.

=cut

use strict;
use warnings;
use Scalar::Util qw(blessed);

our $VERSION = 3.3;

use Carp qw(cluck);
use Params::Validate qw( :all );
use JSON qw(encode_json decode_json);
use SimpleLookupService::QueryObjects::QueryObject;
use SimpleLookupService::Keywords::KeyNames;
use SimpleLookupService::Records::Record;
use SimpleLookupService::Records::RecordFactory;
use SimpleLookupService::Keywords::RecordTypeMapping;

use SimpleLookupService::Client::SimpleLS;

use fields 'INSTANCE', 'LOGGER', 'SERVER', 'QUERY';

sub new {
    my $package = shift;
   
    my $self = fields::new( $package );
   
    return $self;
}

sub init  {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { server => 1, query => 0} );
    
    my $res;
    my $data;
    
    my $server = $parameters{server};
    if(! $server->isa('SimpleLookupService::Client::SimpleLS')){
    	cluck "Error initializing client. Server is not SimpleLookupService::Client::SimpleLS server";
    	return -1;
    }
    
    $self->{SERVER} = $server;
    $self->{SERVER}->connect();
    
    
    
    if (defined $parameters{'query'}){
    	my $ret = $self->_setQuery($parameters{'query'});
    	if($ret != 0){
    		cluck "Error initializing client.";
    		return -1;
    	}
    	
    }    
    
    return 0;
    
}

sub query{
	my ($self, $parameter) = @_;
	
    if (defined $parameter){
    	
    	$self->_setQuery($parameter);
    }
    
    $self->{SERVER}->setConnectionType('GET');
    my $modifiedUrl = "lookup/records/".$self->{QUERY};
    my $result = $self->{SERVER}->send(resourceLocator => $modifiedUrl);
   
    
        # Check the outcome of the response
    if ($result->is_success) {
    	#print $result->content;
        my $jsonResp = decode_json($result->content);
        #print $jsonResp;
        
        my @resultArray = @{$jsonResp};
        my @resObjArray = ();
        foreach my $result (@resultArray){
        	my $tmpType = $result->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TYPE)}->[0];
        	
        	if(defined $tmpType){
        		
        	}
        	my $resultRecord = SimpleLookupService::Records::RecordFactory->instantiate($tmpType);
        	$resultRecord->fromHashRef($result);
        	push @resObjArray, $resultRecord;
        }
        #print scalar @resultArray;
        return(0,\@resObjArray);
    } else {
        return (-1, { message => $result->status_line });
    }
    
} 

sub _setQuery{
	my ($self, $qObject) = @_;
	
	if(defined $qObject){
		if($qObject->isa('SimpleLookupService::QueryObjects::QueryObject')){
			my $data = $qObject->toURLParameters();
			$self->{QUERY} = $data;
			return 0;
		}else{
			cluck "Query should be of type SimpleLookupService::QueryObjects::QueryObject or its subclass ";
			return -1;
		}
	}
	
	
}
