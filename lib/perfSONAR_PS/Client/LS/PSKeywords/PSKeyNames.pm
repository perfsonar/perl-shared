package perfSONAR_PS::Client::LS::PSKeywords::PSKeyNames;

use strict;
use warnings;


use constant {
    LS_KEY_GROUP_COMMUNITIES => "group-communities"
};

# psservice keys
use constant {
    LS_KEY_PSSERVICE_EVENTTYPES => "psservice-eventtypes",
};

# ma keys
use constant {
    LS_KEY_MA_TYPE => "ma-type",
    LS_KEY_MA_TESTS => "ma-tests"
};

#topologyservice keys
use constant {
    LS_KEY_TS_DOMAINS => "ts-domains"
};
#pshost keys
use constant {
    LS_KEY_PSHOST_ROLE => "pshost-role",
    LS_KEY_PSHOST_ACCESSPOLICY => "pshost-access-policy",
    LS_KEY_PSHOST_ACCESSNOTES => "pshost-access-notes",
    LS_KEY_PSHOST_BUNDLE => "pshost-bundle",
    LS_KEY_PSHOST_BUNDLEVERSION => "pshost-bundle-version",
    #deprecated in favor of pshost-bundle-version
    LS_KEY_PSHOST_TOOLKITVERSION => "pshost-toolkitversion", 
    
};

#psinterface keys
use constant {
    LS_KEY_PSINTERFACE_TYPE => "psinterface-type",
    LS_KEY_PSINTERFACE_URNS => "psinterface-urns"   
};

#pstest keys
use constant {
    LS_KEY_PSTEST_NAME => "pstest-name",
    LS_KEY_PSTEST_SOURCE => "pstest-source",
    LS_KEY_PSTEST_DESTINATION => "pstest-destination",
    LS_KEY_PSTEST_EVENTTYPES => "pstest-eventtypes"
};

#pspserson keys
#
#bwctl keys
use constant {
    LS_KEY_BWCTL_TOOLS => "bwctl-tools"
};

1;
