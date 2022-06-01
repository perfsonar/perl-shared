package SimpleLookupService::Records::RecordFactory;

use strict; 
use warnings;

use SimpleLookupService::Keywords::RecordTypeMapping;

sub instantiate {
	my $self          = shift;
    my $requested_type = shift;
   
    my $class = SimpleLookupService::Keywords::RecordTypeMapping::RECORDMAP->{$requested_type};
    
    
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