use strict;
use warnings;

our $VERSION = 4.1;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More;
use Data::Dumper;
use JSON;

use perfSONAR_PS::Client::PSConfig::Addresses::Address;
use perfSONAR_PS::Client::PSConfig::Parsers::Template;

##
# Not this is in the form passed to the template, not a regular pSConfig object
my $jq_json = <<'EOF';
{
    "archives": {
        "example-archive-central": {
            "archiver": "esmond",
            "data": {
                "url": "https://archive.perfsonar.net/esmond/perfsonar/archive/",
                "measurement-agent": "{% scheduled_by_address %}"
            }
        }
    },
    
    "addresses": [
        { 
            "address": "host-a.perfsonar.net", 
            "pscheduler-address": "10.1.1.1",
            "_meta": { "display-name": "Host A" } 
        },
        { 
            "address": "host-b.perfsonar.net", 
            "lead-bind-address": "10.1.1.2" 
        }
    ],
    
    "test": {
        "type": "throughput",
        "spec": {
            "source": "{% address[0] %}",
            "dest": "{% address[1] %}",
            "duration": "PT30S"
        }
    },
    
    "schedule": {
        "repeat": "PT4H",
        "sliprand": true,
        "slip": "PT4H"
    },
    
    "task": {
        "group": "example-group-disjoint",
        "test": "example-test-throughput",
        "schedule": "example-schedule-PT4H",
        "archives": [ "example-archive-central" ],
        "reference": {
            "source-display-name": "{% jq .addresses[0]._meta.\"display-name\" %}",
            "dest-display-name": "{% jq .addresses[1]._meta.\"display-name\" %}"
        }
    }
}
EOF
my $jq_obj = from_json($jq_json);

########
# Template initialization
########
my $addr1 = new perfSONAR_PS::Client::PSConfig::Addresses::Address();
$addr1->data($jq_obj->{'addresses'}->[0]);
my $addr2 = new perfSONAR_PS::Client::PSConfig::Addresses::Address();
$addr2->data($jq_obj->{'addresses'}->[1]);
my $groups = [$addr1, $addr2];
my $template;
ok($template = new perfSONAR_PS::Client::PSConfig::Parsers::Template(
        groups => $groups,
        scheduled_by_address => $addr1,
        jq_obj => $jq_obj,
        flip => 0
));

##
# Useful variables for errors cases
my $uninit_template = new perfSONAR_PS::Client::PSConfig::Parsers::Template();
my $invalid_addr;

########
# No object case
########
is($template->expand(), undef);

########
# Invalid Variable case
########
is($template->expand({ "var" => "{% invalid_var %}" }), undef);
ok($template->error());

########
# Duplicate variable case
########
my $expanded;
ok($expanded =$template->expand({ "var1" => "{% address[0] %}",  "var2" => "{% address[0] %}"}));
is($expanded->{"var1"}, $addr1->address());
is($expanded->{"var2"}, $addr1->address());

########
# address[N] variables
########
#correct variable
is($template->expand({ "var" => "{% address[0] %}" })->{"var"}, $addr1->address());
is($template->expand({ "var" => "{% address[1] %}" })->{"var"}, $addr2->address());
#index too big
is($template->expand({ "var" => "{% address[2] %}" }), undef);
ok($template->error());
#invalid address in groups
$invalid_addr = new perfSONAR_PS::Client::PSConfig::Addresses::Address();
$groups->[0] = $invalid_addr;
is($template->expand({ "var" => "{% address[0] %}" }), undef);
ok($template->error());
$groups->[0] = $addr1; #restore

########
# pscheduler_address[N] variables
########
#correct variable
is($template->expand({ "var" => "{% pscheduler_address[0] %}" })->{"var"}, $addr1->pscheduler_address());
#fallback to address
is($template->expand({ "var" => "{% pscheduler_address[1] %}" })->{"var"}, $addr2->address());
#index too big
is($template->expand({ "var" => "{% pscheduler_address[2] %}" }), undef);
ok($template->error());
#invalid address in groups
$invalid_addr = new perfSONAR_PS::Client::PSConfig::Addresses::Address();
$groups->[0] = $invalid_addr;
is($template->expand({ "var" => "{% pscheduler_address[0] %}" }), undef);
ok($template->error());
$groups->[0] = $addr1; #restore

########
# lead_bind_address[N] variables
########
#correct variable
is($template->expand({ "var" => "{% lead_bind_address[0] %}" })->{"var"}, $addr1->address());
#fallback to address
is($template->expand({ "var" => "{% lead_bind_address[1] %}" })->{"var"}, $addr2->lead_bind_address());
#index too big
is($template->expand({ "var" => "{% lead_bind_address[2] %}" }), undef);
ok($template->error());
#invalid address in groups
$invalid_addr = new perfSONAR_PS::Client::PSConfig::Addresses::Address();
$groups->[0] = $invalid_addr;
is($template->expand({ "var" => "{% lead_bind_address[0] %}" }), undef);
ok($template->error());
$groups->[0] = $addr1; #restore

########
# scheduled_by_address variables
########
#correct variable
is($template->expand({ "var" => "{% scheduled_by_address %}" })->{"var"}, $addr1->address());
#no scheduled_by address
is($uninit_template->expand({ "var" => "{% scheduled_by_address %}" }), undef);
ok($uninit_template->error());
#invalid address
$template->scheduled_by_address(new perfSONAR_PS::Client::PSConfig::Addresses::Address());
is($template->expand({ "var" => "{% scheduled_by_address %}" }), undef);
ok($template->error());
$template->scheduled_by_address($addr1); #restore

########
# flip variables
########
#test false
is($template->expand({ "var" => "{% flip %}" })->{'var'}, JSON::false);
#test true
$template->flip(1);
is($template->expand({ "var" => "{% flip %}" })->{'var'}, JSON::true);
$template->flip(0); #restore

########
# localhost variables
########
#test not flipped
is($template->expand({ "var" => "{% localhost %}" })->{'var'}, 'localhost');
#test flipped
$template->flip(1);
is($template->expand({ "var" => "{% localhost %}" })->{'var'}, $addr1->address());
$template->flip(0); #restore

########
# jq variables
########
#valid
is($template->expand({ "var" => '{% jq .addresses[0]._meta."display-name" %}' })->{'var'}, $addr1->psconfig_meta_param("display-name"));
#null
is($template->expand({ "var" => '{% jq .addresses[1]._meta."display-name" %}' })->{'var'}, JSON::null);
#invalid json
is($template->expand({ "var" => "{% jq .;touch DANGER %}" }), undef);
ok($template->error());

########
#finish testing
########
done_testing();