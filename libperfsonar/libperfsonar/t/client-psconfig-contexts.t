use strict;
use warnings;

our $VERSION = 4.1;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More;
use Data::Dumper;
use JSON;

use perfSONAR_PS::Client::PSConfig::Addresses::Address;
use perfSONAR_PS::Client::PSConfig::Config;
use perfSONAR_PS::Client::PSConfig::Task;
use perfSONAR_PS::Client::PSConfig::Test;
use perfSONAR_PS::Client::PSConfig::Groups::Disjoint;
use perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator;

my $config_json = <<'EOF';
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
    
    "addresses": {
        "host-a.perfsonar.net": { "address": "host-a.perfsonar.net", "contexts": ["changenothing"] },
        "host-b.perfsonar.net": { "address": "host-b.perfsonar.net" },
        "host-c.perfsonar.net": { "address": "host-c.perfsonar.net" }
    },
    
    "contexts": {
        "changenothing": { "context": "changenothing", "data": {} }
    },
    
    "groups": {
         "example-group-disjoint": {
            "type": "disjoint",
            "a-addresses": [
                { "name": "host-a.perfsonar.net" }
            ],
            "b-addresses": [
                { "name": "host-a.perfsonar.net" },
                { "name": "host-b.perfsonar.net" },
                { "name": "host-c.perfsonar.net" }
            ]
        }
    },
    
    "tests": {
        "example-test-throughput": {
            "type": "throughput",
            "spec": {
                "source": "{% address[0] %}",
                "dest": "{% address[1] %}",
                "duration": "PT30S"
            }
        }
    },
    
    "schedules": {
        "example-schedule-PT4H": {
            "repeat": "PT4H",
            "sliprand": true,
            "slip": "PT4H"
        }
    },
    
    "tasks": {
        "example-task-throughput": {
            "group": "example-group-disjoint",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        }
    }
}
EOF
my $config_obj = from_json($config_json);

########
# Test contexts
########
my $tg;
my $psconfig;
my $task;

####
# Test setting scheduled_by to excessive value
ok($psconfig = new perfSONAR_PS::Client::PSConfig::Config(data => $config_obj));
ok($task = $psconfig->task("example-task-throughput"));
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(psconfig => $psconfig, task_name => "example-task-throughput"));
ok($tg->start());
ok($tg->next());

##
# Test pScheduler conversion
my $psched_task;
ok($psched_task = $tg->pscheduler_task());

##
# Invalid contexts
$tg->stop();
$psconfig->address("host-a.perfsonar.net")->add_context_ref('invalid');
ok($tg->start());
ok($tg->next()); #still returns addresses but there will be an error
ok($tg->error());

########
#finish testing
########
done_testing();