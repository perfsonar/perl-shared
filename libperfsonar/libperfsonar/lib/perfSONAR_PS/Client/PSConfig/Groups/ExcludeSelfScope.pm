package perfSONAR_PS::Client::PSConfig::Groups::ExcludeSelfScope;

use strict;
use warnings;


#Constants for values
use constant {
    HOST => "host",
    ADDRESS => "address",
    DISABLED => "disabled",
};

#Constant for validation
use constant {
    VALID_VALUES => {"host" => 1, "address" => 1,"disabled"=> 1}
};


1;
