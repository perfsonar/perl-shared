use strict;
use warnings;

our $VERSION = 4.1;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More;
use Data::Dumper;
use JSON;

use perfSONAR_PS::Client::PSConfig::Addresses::Address;
use perfSONAR_PS::Client::PSConfig::Archive;
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
        "host-a.perfsonar.net": { "address": "host-a.perfsonar.net", "_meta": { "display-name": "Host A" } },
        "host-b.perfsonar.net": { "address": "host-b.perfsonar.net", "lead-bind-address": "10.1.1.1" },
        "host-c.perfsonar.net": { "address": "host-c.perfsonar.net" }
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
        },
        "example-test-latencybg": {
            "type": "latencybg",
            "spec": {
                "source": "{% address[0] %}",
                "dest": "{% address[1] %}",
                "flip": "{% flip %}"
            },
            "_meta": {"foo": "bar"}
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
            "archives": [ "example-archive-central" ],
            "tools": [ "nuttcp" ],
            "reference": {
                "source-display-name": "{% jq .addresses[0]._meta.\"display-name\" %}",
                "dest-display-name": "{% jq .addresses[1]._meta.\"display-name\" %}"
            }
        },
        "example-task-latencybg": {
            "group": "example-group-disjoint",
            "test": "example-test-latencybg",
            "archives": [ "example-archive-central" ],
            "reference": {
                "source-display-name": "{% jq .addresses[0]._meta.\"display-name\" %}",
                "dest-display-name": "{% jq .addresses[1]._meta.\"display-name\" %}"
            }
        }
    }
}
EOF
my $config_obj = from_json($config_json);

########
# Test error cases where values uninitialized
########
my $tg;
my $psconfig;
my $task;
ok($psconfig = new perfSONAR_PS::Client::PSConfig::Config());
ok($task = new perfSONAR_PS::Client::PSConfig::Task());
ok($psconfig->task("example", $task));

## Not started
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator());
is($tg->next(), undef);
is($tg->pscheduler_task(), undef);

## No task name
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator());
is($tg->start(), undef);
ok($tg->error());

## Invalid task name
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(task_name => "invalid"));
is($tg->start(), undef);
ok($tg->error());

## Invalid group name
ok($psconfig->group("example", new perfSONAR_PS::Client::PSConfig::Groups::Disjoint()));
ok($task->group_ref("invalid"));

ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(psconfig => $psconfig, task_name => "example"));
is($tg->start(), undef);
ok($tg->error());
ok($task->group_ref("example"));

## Invalid test name
ok($psconfig->test("example", new perfSONAR_PS::Client::PSConfig::Test()));
ok($task->test_ref("invalid"));
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(psconfig => $psconfig, task_name => "example"));
is($tg->start(), undef);
ok($tg->error());
ok($task->test_ref("example"));

##Finally start legitimately
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(psconfig => $psconfig, task_name => "example"));
ok($tg->start());


####
# Test setting scheduled_by to excessive value
ok($psconfig = new perfSONAR_PS::Client::PSConfig::Config(data => $config_obj));
ok($task = $psconfig->task("example-task-throughput"));
ok($task->scheduled_by(2)); #invalid scheduled_by 
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(psconfig => $psconfig, task_name => "example-task-throughput"));
ok($tg->start());
is($tg->next(), undef);
ok($tg->error());
is($task->scheduled_by(0), 0); #valid scheduled_by 

####
# Test setting match address - including when case may not match
ok($psconfig = new perfSONAR_PS::Client::PSConfig::Config(data => $config_obj));
ok($task = $psconfig->task("example-task-throughput"));
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
                                                            psconfig => $psconfig, 
                                                            task_name => "example-task-throughput", 
                                                            match_addresses => [ "HOST-C.perfsonar.net" ]
                                                        ));
ok($tg->start());
ok($tg->next());

###
# Test pscheduler task and tool
my $psched_task;
ok($psched_task = $tg->pscheduler_task());
is($psched_task->requested_tools()->[0], 'nuttcp');
is($psched_task->checksum(), 's+EUR1rska59/heKpxs1Kw'); #verify we got the JSON we expected


####
# Test with no schedule
ok($psconfig = new perfSONAR_PS::Client::PSConfig::Config(data => $config_obj));
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
                                                            psconfig => $psconfig, 
                                                            task_name => "example-task-latencybg"
                                                        ));
ok($tg->start());
ok($tg->next());

####
# Test pscheduler conversion
ok($psched_task = $tg->pscheduler_task());
is($psched_task->checksum(), 'k9sS9NwyA9vqGXIpK0o2dQ'); #verify we got the JSON we expected

####################
# These mess with JSON - put new tests after these with caution
####################

####
# Test _get_archives edge cases
# test with use_psconfig_archives disabled and default archives enabled (with duplicate)
my $default_archive = new perfSONAR_PS::Client::PSConfig::Archive();
$default_archive->archiver("esmond");
$default_archive->archiver_data_param("url", "http://localhost/");
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
                                                            psconfig => $psconfig, 
                                                            task_name => "example-task-latencybg",
                                                            use_psconfig_archives => 0,
                                                            default_archives => [
                                                                $default_archive,
                                                                $default_archive #duplicate
                                                            ]
                                                        ));
ok($tg->start());
ok($tg->next());
is(@{$tg->expanded_archives()}, 1);
is($tg->expanded_archives()->[0]->{'archiver'}, 'esmond');
is($tg->expanded_archives()->[0]->{'data'}->{'url'}, "http://localhost/");

##
# test invalid archive ref
ok($task = $psconfig->task("example-task-throughput"));
ok($task->add_archive_ref("invalid"));
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
                                                            psconfig => $psconfig, 
                                                            task_name => "example-task-throughput"
                                                        ));
ok($tg->start());
ok($tg->next());
ok($tg->error());

##
# test duplicate archive ref
ok($task->archive_refs(["example-archive-central", "example-archive-central"]));
($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
                                                            psconfig => $psconfig, 
                                                            task_name => "example-task-throughput"
                                                        ));
ok($tg->start());
ok($tg->next());
is(@{$tg->expanded_archives()}, 1);

####
# test private funtions required params
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
                                                            psconfig => $psconfig, 
                                                            task_name => "example-task-latencybg"
                                                        ));
is($tg->_is_no_agent(), undef);
is(@{$tg->_get_archives()}, 0);
is(@{$tg->_get_contexts()}, 0);
is(($tg->_handle_next_error([""])), 1);
is(($tg->_handle_next_error([ new perfSONAR_PS::Client::PSConfig::Addresses::Address() ])), 1);

########
#finish testing
########
done_testing();
