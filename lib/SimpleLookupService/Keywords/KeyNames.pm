package SimpleLookupService::Keywords::KeyNames;

use strict;
use warnings;

# Record keys
use constant {
    LS_KEY_TYPE => "type",
    LS_KEY_EXPIRES => "expires",
    LS_KEY_TTL => "ttl",
    LS_KEY_URI => "uri",
    LS_KEY_CLIENT_UUID => "client-uuid",
};

#General keys

use constant {
    LS_KEY_OPERATOR => "operator",
    LS_KEY_OPERATOR_SUFFIX => "-operator"
};


#location keys
use constant {
	LS_KEY_LOCATION_SITENAME => "location-sitename",
    LS_KEY_LOCATION_CITY => "location-city",
    LS_KEY_LOCATION_STATE => "location-state",
    LS_KEY_LOCATION_COUNTRY => "location-country",
    LS_KEY_LOCATION_CODE => "location-code",
    LS_KEY_LOCATION_LATITUDE => "location-latitude",
    LS_KEY_LOCATION_LONGITUDE => "location-longitude"
};

#group keys
use constant{
	LS_KEY_GROUP_DOMAINS => "group-domains"
};

#service keys
use constant {
    LS_KEY_SERVICE_NAME => "service-name",
    LS_KEY_SERVICE_TYPE => "service-type",
    LS_KEY_SERVICE_VERSION => "service-version",
    LS_KEY_SERVICE_HOST => "service-host",
    LS_KEY_SERVICE_LOCATOR => "service-locator",
    LS_KEY_SERVICE_ADMINISTRATORS => "service-administrators",
    LS_KEY_SERVICE_AUTHN_TYPE => "service-authentication-type"
};

#host names
use constant {	
    LS_KEY_HOST_NAME => "host-name",
    LS_KEY_HOST_HARDWARE_MEMORY => "host-hardware-memory",
    LS_KEY_HOST_HARDWARE_PROCESSORSPEED => "host-hardware-processorspeed",
    LS_KEY_HOST_HARDWARE_PROCESSORCOUNT => "host-hardware-processorcount",
    LS_KEY_HOST_HARDWARE_PROCESSORCORE => "host-hardware-processorcore",
    LS_KEY_HOST_HARDWARE_CPUID => "host-hardware-cpuid",
    
    LS_KEY_HOST_OS_NAME => "host-os-name",
    LS_KEY_HOST_OS_VERSION => "host-os-version",
    LS_KEY_HOST_OS_KERNEL => "host-os-kernel",
    
    LS_KEY_HOST_NET_TCP_CONGESTIONALGORITHM => "host-net-tcp-congestionalgorithm",
    LS_KEY_HOST_NET_TCP_MAXBUFFER_SEND => "host-net-tcp-maxbuffer-send",
    LS_KEY_HOST_NET_TCP_MAXBUFFER_RECV => "host-net-tcp-maxbuffer-recv",
    LS_KEY_HOST_NET_TCP_AUTOTUNEMAXBUFFER_SEND => "host-net-tcp-autotunemaxbuffer-send",
    LS_KEY_HOST_NET_TCP_AUTOTUNEMAXBUFFER_RECV => "host-net-tcp-autotunemaxbuffer-recv",
    LS_KEY_HOST_NET_TCP_MAXBACKLOG => "host-net-tcp-maxbacklog",
    LS_KEY_HOST_NET_TCP_MAXACHIEVABLE => "host-net-tcp-maxachievable",
    LS_KEY_HOST_NET_TCP_INTERFACES => "host-net-interfaces",
    
    LS_KEY_HOST_VM => "host-vm",
    LS_KEY_HOST_MANUFACTURER => "host-manufacturer",
    LS_KEY_HOST_PRODUCT_NAME => "host-productname",
    
    LS_KEY_HOST_ADMINISTRATORS => "host-administrators"
};


#interface keys

use constant {	
    LS_KEY_INTERFACE_NAME => "interface-name",
    LS_KEY_INTERFACE_ADDRESSES => "interface-addresses",
    LS_KEY_INTERFACE_SUBNET => "interface-subnet",
    LS_KEY_INTERFACE_CAPACITY => "interface-capacity",
    LS_KEY_INTERFACE_MAC => "interface-mac",
    LS_KEY_INTERFACE_MTU => "interface-mtu"
};

#person keys
use constant {	
    LS_KEY_PERSON_NAME => "person-name",
    LS_KEY_PERSON_EMAILS => "person-emails",
    LS_KEY_PERSON_PHONENUMBERS => "person-phonenumbers",
    LS_KEY_PERSON_ORGANIZATION => "person-organization",  
};

1;
