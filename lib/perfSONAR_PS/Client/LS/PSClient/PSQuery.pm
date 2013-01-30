package perfSONAR_PS::Client::LS::PSClient::PSQuery;

use base 'SimpleLookupService::Client::Query';

use Carp qw(cluck);
use Params::Validate qw( :all );
use JSON qw(encode_json decode_json);
use perfSONAR_PS::Client::LS::PSRecords::PSRecordFactory;
use perfSONAR_PS::Client::LS::PSKeywords::PSRecordTypeMapping;
use SimpleLookupService::Keywords::KeyNames;

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
        	my $resultRecord = perfSONAR_PS::Client::LS::PSRecords::PSRecordFactory->instantiate($tmpType);
        	$resultRecord->fromHashRef($result);
        	push @resObjArray, $resultRecord;
        }
        #print scalar @resultArray;
        return(0,\@resObjArray);
    } else {
        return (-1, { message => $result->status_line });
    }
    
} 

1;