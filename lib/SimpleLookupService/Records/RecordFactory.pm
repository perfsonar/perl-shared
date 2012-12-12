package SimpleLookupService::Records::RecordFactory;

use strict; 
use warnings;

use SimpleLookupService::Keywords::RecordTypeMapping;

sub instantiate {
	my $self          = shift;
    my $requested_type = shift;
   
    my $class = SimpleLookupService::Keywords::RecordTypeMapping::RECORDMAP->{$requested_type};
    
    print $class;
    
    if(defined $class){
    	my $location       = "$class.pm";

    	return $class->new(@_);
    }else{
    	return(-1,{"Undefined record-type"});
    }
   
}
1;