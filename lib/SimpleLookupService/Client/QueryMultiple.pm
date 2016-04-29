package SimpleLookupService::Client::QueryMultiple;

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
use SimpleLookupService::Client::Bootstrap;

use SimpleLookupService::Client::SimpleLS;

use URI;

use fields 'INSTANCE', 'LOGGER', 'SERVER', 'QUERY';

sub new {
    my $package = shift;
   
    my $self = fields::new( $package );
   
    return $self;
    $self->{SERVER}=[];
    $self->{QUERY}=[];
}

sub init  {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { bootstrap_server => 0, query => 0} );
    
    my $res;
    my $data;
    
    my $bootstrap_server;
    
    if (defined $parameters{'bootstrap_server'}){
    	$bootstrap_server = $parameters{'bootstrap_server'};
    	if(!$bootstrap_server->isa('SimpleLookupService::Client::SimpleLS')){
    		cluck "Error initializing client. Bootstrap Server is not SimpleLookupService::Client::SimpleLS server";
    		return -1;
   		}
    }else{
    	
    	$bootstrap_server = SimpleLookupService::Client::SimpleLS->new();
    	$bootstrap_server->init(host=>'ps-west.es.net',port=>80);
    	
    }
    
    my $result = $bootstrap_server->send(resourceLocator => '/lookup/activehosts.json');
    my $json_server_list = decode_json($result->content);

    
    my @server_list = @{$json_server_list->{'hosts'}};
    
    foreach my $ls_url (@server_list){
    	my $sls_server = SimpleLookupService::Client::SimpleLS->new();
    	my $uri = URI->new($ls_url->{'locator'} );
    	$sls_server->init({host=>$uri->host, port=>$uri->port});
    	push @{$self->{'SERVER'}}, $sls_server;
    }
    
    
    
    
   
    foreach my $server (@{$self->{'SERVER'}}){
    	$server->connect();
    }
    
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
    	
    	$self->addQuery($parameter);
    }
    
     my @resObjArray = ();
     
     
     foreach my $server (@{$self->{'SERVER'}}){
     	
     	$server->setConnectionType('GET');
     	foreach my $query (@{$self->{QUERY}}){
     		my $modifiedUrl = "lookup/records/".$query;
    		my $result = $server->send(resourceLocator => $modifiedUrl);
    		
    		if ($result->is_success) {
    			my $jsonResp = decode_json($result->content);
        		my @resultArray = @{$jsonResp};
       
        		foreach my $result (@resultArray){
        			my $tmpType = $result->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TYPE)}->[0];
        	
        			my $resultRecord = SimpleLookupService::Records::RecordFactory->instantiate($tmpType);
        			$resultRecord->fromHashRef($result);
        			push @resObjArray, $resultRecord;
        			}	
    		}else{
    			cluck "Error retrieving result from ". $server->getHost();
    			return -1;
    		}
    		#ignores error results
     		
     	}
     }
     return(0,\@resObjArray);
    
} 

sub _setQuery{
	my ($self, $qObject) = @_;
	
	if(defined $qObject){
		if($qObject->isa('SimpleLookupService::QueryObjects::QueryObject')){
			my $data = $qObject->toURLParameters();
			push @{$self->{QUERY}}, $data;
			return 0;
		}else{
			cluck "Query should be of type SimpleLookupService::QueryObjects::QueryObject or its subclass ";
			return -1;
		}
	}
	
	
}

sub addQuery(){
	my ($self, $qObject) = @_;
	
	if(defined $qObject){
		if($qObject->isa('SimpleLookupService::QueryObjects::QueryObject')){
			$self->_setQuery($qObject);
			return 0;
		}else{
			cluck "Query should be of type SimpleLookupService::QueryObjects::QueryObject or its subclass ";
			return -1;
		}
		
	}
	
}
