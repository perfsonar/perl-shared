package perfSONAR_PS::Client::LS::PSRecords::PSRecordFactory;

use strict; 
use warnings;

use SimpleLookupService::Records::Record;
use perfSONAR_PS::Client::LS::PSKeywords::PSRecordTypeMapping;

sub instantiate {
	my $self          = shift;
    my $requested_type = shift;
   
    my $class = perfSONAR_PS::Client::LS::PSKeywords::PSRecordTypeMapping::RECORDMAP->{$requested_type};
    
    
    if(defined $class){
    	#my $location       = "$class.pm";
	    my $location = $class;
	    
	    $location =~ s/::/\//g;

	    $location .= ".pm";
	    require $location;
    	return $class->new(@_);
    }else{
    	return SimpleLookupService::Records::Record->new(@_);
    }
   
}
1;