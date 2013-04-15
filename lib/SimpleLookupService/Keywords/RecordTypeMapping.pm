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
                    (SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_PERSON) => "SimpleLookupService::Records::Directory::Person",
				}
		
};

use constant {
	
	QUERYMAP => {
					(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_SERVICE) => "SimpleLookupService::QueryObjects::Network::ServiceQueryObject",
   					(SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_HOST) => "SimpleLookupService::QueryObjects::Network::HostQueryObject",
                    (SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_INTERFACE) => "SimpleLookupService::QueryObjects::Network::InterfaceQueryObject",
                    (SimpleLookupService::Keywords::Values::LS_VALUE_TYPE_PERSON) => "SimpleLookupService::QueryObjects::Directory::PersonQueryObject",
				}
		
};
1;