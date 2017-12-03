use strict;
use warnings;

our $VERSION = 4.1;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More;
use Data::Dumper;
use JSON;

use perfSONAR_PS::Client::PSConfig::Config;
use perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator;

##
# define config to be used for testing
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
        "host-a.perfsonar.net": { "address": "host-a.perfsonar.net" },
        "host-b.perfsonar.net": { "address": "host-b.perfsonar.net", "no-agent": true },
        "host-c.perfsonar.net": { "address": "host-c.perfsonar.net", "host": "host-c" },
        "host-d.perfsonar.net": { 
            "address": "host-d.perfsonar.net",  
            "no-agent": true,
            "labels": {
                "ipv4": {"address": "10.0.1.1"}
            }
        },
        "host-e.perfsonar.net": { 
            "address": "host-e.perfsonar.net",  
            "host": "host-e",
            "labels": {
                "ipv4": {"address": "10.0.1.2"}
            }
        },
        "host-f.perfsonar.net": { 
            "address": "host-f.perfsonar.net",  
            "no-agent": true,
            "remote-addresses": {
                "host-a.perfsonar.net": {
                    "address": "host-fa.perfsonar.net",  
                    "labels":{
                        "ipv4": {"address": "10.0.1.3"}
                    }
                }
            }
        }
    },
    
    "hosts": {
        "host-c": {
            "no-agent": true
        },
        "host-e": {
            "no-agent": true
        }
    },
    
    "groups": {
         "example-group-mesh": {
            "type": "mesh",
            "addresses": [
                { "name": "host-a.perfsonar.net" },
                { "name": "host-b.perfsonar.net" },
                { "name": "host-c.perfsonar.net" },
                { "name": "host-d.perfsonar.net", "label": "ipv4" },
                { "name": "host-e.perfsonar.net", "label": "ipv4" },
                { "name": "host-f.perfsonar.net", "label": "ipv4" },
                { "name": "host-f.perfsonar.net" }
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
            "group": "example-group-mesh",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        }
    }
}
EOF
my $config_obj = from_json($config_json);


########
# Initialize psconfig
########
my $psconfig;
ok($psconfig = new perfSONAR_PS::Client::PSConfig::Config(data => $config_obj));
is($psconfig->validate(), 0);

########
# Iterate through entire mesh
########
my $tg;
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-throughput',
    match_addresses => ['host-a.perfsonar.net']
));
ok($tg->start());

my @pair;
##
# a->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-a.perfsonar.net");
is($pair[1]->address(), "host-b.perfsonar.net");
##
# a->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-a.perfsonar.net");
is($pair[1]->address(), "host-c.perfsonar.net");
##
# a->d
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-a.perfsonar.net");
is($pair[1]->address(), "10.0.1.1");
##
# a->e
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-a.perfsonar.net");
is($pair[1]->address(), "10.0.1.2");
##
# a->f
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-a.perfsonar.net");
is($pair[1]->address(), "10.0.1.3");
##
# a->f(default remote)
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-a.perfsonar.net");
is($pair[1]->address(), "host-fa.perfsonar.net");
##
# b->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-b.perfsonar.net");
is($pair[1]->address(), "host-a.perfsonar.net");
##
# c->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-c.perfsonar.net");
is($pair[1]->address(), "host-a.perfsonar.net");
##
# d->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.0.1.1");
is($pair[1]->address(), "host-a.perfsonar.net");
##
# e->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.0.1.2");
is($pair[1]->address(), "host-a.perfsonar.net");
##
# f->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.0.1.3");
is($pair[1]->address(), "host-a.perfsonar.net");
##
# f(default remote)->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-fa.perfsonar.net");
is($pair[1]->address(), "host-a.perfsonar.net");

##
# No more
##
#is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);


########
#finish testing
########
done_testing();