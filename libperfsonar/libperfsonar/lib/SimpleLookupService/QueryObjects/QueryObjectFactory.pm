package SimpleLookupService::QueryObjects::QueryObjectFactory;

use strict; 
use warnings;

use SimpleLookupService::Keywords::RecordTypeMapping;

sub instantiate {
	my $self          = shift;
    my $requested_type = shift;
   
    my $class = SimpleLookupService::Keywords::RecordTypeMapping::QUERYMAP->{$requested_type};
    
    
    if(defined $class){
    	#my $location       = "$class.pm";
	    my $location = $class;
	    
	    $location =~ s/::/\//g;

	    $location .= ".pm";
	    require $location;
    	return $class->new(@_);
    }else{
    	return SimpleLookupService::QueryObjects::QueryObject->new(@_);
    }
   
}
1;