package perfSONAR_PS::Client::LS::PSKeywords::PSValues;

use strict;
use warnings;

#psservice eventtype values
use constant {
    LS_VALUE_EVENTTYPE_TOPOLOGYSERVICE => ["http://ggf.org/ns/nmwg/topology/20070809"],
    LS_VALUE_EVENTTYPE_PSBMA_OWAMP => ["http://ggf.org/ns/nmwg/tools/owamp/2.0/", "http://ggf.org/ns/nmwg/characteristic/delay/summary/20070921"],
    LS_VALUE_EVENTTYPE_PSBMA_OWAMP_BUCKETS => ["http://ggf.org/ns/nmwg/characteristic/delay/summary/20110317/"],
    LS_VALUE_EVENTTYPE_PSBMA_BWCTL => ["http://ggf.org/ns/nmwg/tools/iperf/2.0", "http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0"],
    LS_VALUE_EVENTTYPE_SNMPMA => ["http://ggf.org/ns/nmwg/characteristic/utilization/2.0", "http://ggf.org/ns/nmwg/tools/snmp/2.0"],
    LS_VALUE_EVENTTYPE_PINGERMA => ["http://ggf.org/ns/nmwg/tools/pinger/2.0/", "http://ggf.org/ns/nmwg/tools/pinger/2.0"],
    LS_VALUE_EVENTTYPE_TRACEROUTEMA => ["http://ggf.org/ns/nmwg/tools/traceroute/2.0/"],
    
    LS_VALUE_TYPE_PSTEST => "pstest"
    
};
1;