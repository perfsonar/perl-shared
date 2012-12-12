package SimpleLookupService::Keywords::RecordTypeMapping;

use strict;
use warnings;

use SimpleLookupService::Keywords::Values;

# Record keys
use constant {
	
	RECORDMAP => {
					(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_SERVICE) => "SimpleLookupService::Records::Network::Service",
   					(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_HOST) => "SimpleLookupService::Records::Network::Host",
                    (SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_INTERFACE) => "SimpleLookupService::Records::Network::Interface",
                    (SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_PERSON) => "SimpleLookupService::Records::Network::Person",
				}
		
};
    

1;