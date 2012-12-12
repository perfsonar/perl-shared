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

our $VERSION = 3.2;

use Params::Validate qw( :all );
use JSON qw(encode_json decode_json);
use SimpleLookupService::QueryObjects::QueryObject;
use SimpleLookupService::Keywords::KeyNames;
use SimpleLookupService::Records::Record;
use SimpleLookupService::Records::RecordFactory;
use SimpleLookupService::Keywords::RecordTypeMapping;

use base 'SimpleLookupService::Client::SimpleLS';

sub init  {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { url => 1, timeout=> 0, query => 0} );
    my $data;
    $self->SUPER::init({
           url => $parameters{'url'},
           timeout => $parameters{'timeout'},
           connectionType => 'GET',
    	});
    if(defined $parameters{'query'}){
    	_setQuery($parameters{'query'});
    }
    
    return $self;
    
}

sub query{
	my ($self, $parameter) = @_;
	
    if (defined $parameter){
    	
    	$self->_setRQuery($parameter);
    }
    
    
    my $result = $self->SUPER::connect();
    
        # Check the outcome of the response
    if ($result->is_success) {
    	#print $result->content;
        my $jsonResp = decode_json($result->content);
        #print $jsonResp;
        
        my @resultArray = @{$jsonResp};
        my @resObjArray = ();
        foreach my $result (@resultArray){
        	my $tmpType = $result->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TYPE)}->[0];
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
		if($qObject->isa('SimpleLookupService::Records::QueryObject')){
			my $data = $qObject->toURLParameter;
		
			my $url = $self->SUPER::getUrl();
		
			$url .= $data;
			$self->SUPER::setUrl({url => $url});
		}else{
			die "Query should be of type SimpleLookupService::QueryObjects::QueryObject or its subclass ";
		}
	}
	
	
}