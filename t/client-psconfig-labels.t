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
                "measurement-agent": "$requesting-agent"
            }
        }
    },
    
    "addresses": {
        "host-a.perfsonar.net": { 
            "address": "host-a.perfsonar.net",
            "labels": {
                "ipv4": {"address": "10.1.1.1"},
                "ipv6": {"address": "fde4:68e1:c5d3:f183::a"}
            }
            
        },
        "host-b.perfsonar.net": { 
            "address": "host-b.perfsonar.net",
            "labels": {
                "ipv4": {"address": "10.1.1.2"},
                "alt": {"address": "10.1.2.2"},
                "ipv6": {"address": "fde4:68e1:c5d3:f183::b"}
            }
            
        },
        "host-c.perfsonar.net": { 
            "address": "host-c.perfsonar.net",
            "labels": {
                "ipv4": {"address": "10.1.1.3"},
                "ipv6": {"address": "fde4:68e1:c5d3:f183::c"}
            }
        },
        "host-d.perfsonar.net": { 
            "address": "host-d.perfsonar.net",
            "disabled": true,
            "labels": {
                "ipv4": {"address": "10.1.1.4"},
                "ipv6": {"address": "fde4:68e1:c5d3:f183::d"}
            }
        },
        "host-e.perfsonar.net": { 
            "address": "host-e.perfsonar.net",
            "host": "host-ef",
            "labels": {
                "ipv4": {"address": "10.1.1.5"},
                "ipv6": {"address": "fde4:68e1:c5d3:f183::e"}
            }
        },
        "host-f.perfsonar.net": { 
            "address": "host-f.perfsonar.net",
            "host": "host-ef",
            "labels": {
                "ipv4": {"address": "10.1.1.6"},
                "ipv6": {"address": "fde4:68e1:c5d3:f183::f"}
            }
        }
    },
    
    "hosts": {
        "host-ef": {}
    },
    
    "groups": {
         "example-group-mesh": {
            "type": "mesh",
            "addresses": [
                { "name": "host-a.perfsonar.net", "label": "ipv4" },
                { "name": "host-b.perfsonar.net", "label": "ipv4" },
                { "name": "host-b.perfsonar.net", "label": "alt" },
                { "name": "host-c.perfsonar.net" },
                { "name": "host-d.perfsonar.net", "label": "ipv4" }
            ]
        },
        "example-group-default-label": {
            "type": "mesh",
            "default-address-label": "ipv4",
            "addresses": [
                { "name": "host-a.perfsonar.net" },
                { "name": "host-b.perfsonar.net", "label": "alt" },
                { "name": "host-c.perfsonar.net" }
            ]
        },
        "example-group-excl-address": {
            "type": "mesh",
            "excludes-self": "address",
            "default-address-label": "ipv4",
            "addresses": [
                { "name": "host-a.perfsonar.net" },
                { "name": "host-b.perfsonar.net", "label": "ipv4" },
                { "name": "host-b.perfsonar.net", "label": "alt" },
                { "name": "host-c.perfsonar.net" }
            ]
        },
        "example-group-excl-host": {
            "type": "mesh",
            "excludes-self": "host",
            "default-address-label": "ipv4",
            "addresses": [
                { "name": "host-a.perfsonar.net" },
                { "name": "host-b.perfsonar.net", "label": "ipv4" },
                { "name": "host-b.perfsonar.net", "label": "alt" },
                { "name": "host-c.perfsonar.net" },
                { "name": "host-e.perfsonar.net" },
                { "name": "host-f.perfsonar.net" }
            ]
        },
        "example-group-excl-disabled": {
            "type": "mesh",
            "excludes-self": "disabled",
            "default-address-label": "ipv4",
            "addresses": [
                { "name": "host-a.perfsonar.net" },
                { "name": "host-b.perfsonar.net", "label": "ipv4" },
                { "name": "host-b.perfsonar.net", "label": "alt" },
                { "name": "host-c.perfsonar.net" },
                { "name": "host-e.perfsonar.net" },
                { "name": "host-f.perfsonar.net" }
            ]
        }
    },
    
    "tests": {
        "example-test-throughput": {
            "type": "throughput",
            "spec": {
                "source": "$group::0",
                "dest": "$group::1",
                "duration": "PT30S"
            }
        },
        "example-test-latencybg": {
            "type": "latencybg",
            "spec": {
                "source": "$group::0",
                "dest": "$group::1"
            }
        },
        "example-test-trace": {
            "type": "trace",
            "spec": {
                "source": "$group::0",
                "dest": "$group::1"
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
        },
        "example-task-default-label": {
            "group": "example-group-default-label",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-excl-address": {
            "group": "example-group-excl-address",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-excl-host": {
            "group": "example-group-excl-host",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-excl-disabled": {
            "group": "example-group-excl-disabled",
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
my @errors = $psconfig->validate();
if(@errors){
    foreach my $error(@errors){
        diag "Error: " . $error->message . "\n";
        diag "Path: " . $error->path . "\n\n";
    }
    print "Invalid JSON\n";
    exit 1;
}
########
# Iterate through entire mesh
########
my $tg;
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-throughput'
));
ok($tg->start());

my @pair;
##
# a->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.1.2");
##
# a->b(alt)
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.2.2");
##
# a->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "host-c.perfsonar.net");
##
# b->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.2");
is($pair[1]->address(), "10.1.1.1");
##
# b->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.2");
is($pair[1]->address(), "host-c.perfsonar.net");
##
# b(alt)->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "10.1.1.1");
##
# b(alt)->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "host-c.perfsonar.net");
##
# c->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-c.perfsonar.net");
is($pair[1]->address(), "10.1.1.1");
##
# c->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-c.perfsonar.net");
is($pair[1]->address(), "10.1.1.2");
##
# c->b(alt)
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-c.perfsonar.net");
is($pair[1]->address(), "10.1.2.2");

##
# No more
##
#is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate through default labels
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-default-label'
));
ok($tg->start());

##
# a->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.2.2");
##
# a->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.1.3");
##
# b->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "10.1.1.1");
##
# b->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "10.1.1.3");
##
# c->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.1.1");
##
# c->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.2.2");

##
# No more
##
#is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate with exclude-self scope of address
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-excl-address'
));
ok($tg->start());

##
# a->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.1.2");
##
# a->b(alt)
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.2.2");
##
# a->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.1.3");
##
# b->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.2");
is($pair[1]->address(), "10.1.1.1");
##
# b->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.2");
is($pair[1]->address(), "10.1.1.3");
##
# b(alt)->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "10.1.1.1");
##
# b(alt)->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "10.1.1.3");
##
# c->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.1.1");
##
# c->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.1.2");
##
# c->b(alt)
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.2.2");

##
# No more
##
#is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate with exclude-self scope of host
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-excl-host'
));
ok($tg->start());

##
# a->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.1.2");
##
# a->b(alt)
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.2.2");
##
# a->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.1.3");
##
# a->e
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.1.5");
##
# a->f
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.1.6");
##
# b->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.2");
is($pair[1]->address(), "10.1.1.1");
##
# b->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.2");
is($pair[1]->address(), "10.1.1.3");
##
# b->e
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.2");
is($pair[1]->address(), "10.1.1.5");
##
# b->f
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.2");
is($pair[1]->address(), "10.1.1.6");
##
# b(alt)->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "10.1.1.1");
##
# b(alt)->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "10.1.1.3");
##
# b(alt)->e
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "10.1.1.5");
##
# b(alt)->f
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "10.1.1.6");
##
# c->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.1.1");
##
# c->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.1.2");
##
# c->b(alt)
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.2.2");
##
# c->e
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.1.5");
##
# c->f
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.1.6");
##
# e->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.5");
is($pair[1]->address(), "10.1.1.1");
##
# e->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.5");
is($pair[1]->address(), "10.1.1.2");
##
# e->b(alt)
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.5");
is($pair[1]->address(), "10.1.2.2");
##
# e->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.5");
is($pair[1]->address(), "10.1.1.3");

##
# f->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.6");
is($pair[1]->address(), "10.1.1.1");
##
# f->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.6");
is($pair[1]->address(), "10.1.1.2");
##
# f->b(alt)
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.6");
is($pair[1]->address(), "10.1.2.2");
##
# f->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.6");
is($pair[1]->address(), "10.1.1.3");

##
# No more
##
#is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate with exclude-self scope of disabled
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-excl-disabled'
));
ok($tg->start());

##
# a->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.1.1");
##
# a->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.1.2");
##
# a->b(alt)
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.2.2");
##
# a->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.1.3");
##
# a->e
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.1.5");
##
# a->f
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.1");
is($pair[1]->address(), "10.1.1.6");
##
# b->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.2");
is($pair[1]->address(), "10.1.1.1");
##
# b->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.2");
is($pair[1]->address(), "10.1.1.2");
##
# b->b(alt)
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.2");
is($pair[1]->address(), "10.1.2.2");
##
# b->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.2");
is($pair[1]->address(), "10.1.1.3");
##
# b->e
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.2");
is($pair[1]->address(), "10.1.1.5");
##
# b->f
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.2");
is($pair[1]->address(), "10.1.1.6");
##
# b(alt)->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "10.1.1.1");
##
# b(alt)->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "10.1.1.2");
##
# b(alt)->b(alt)
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "10.1.2.2");
##
# b(alt)->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "10.1.1.3");
##
# b(alt)->e
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "10.1.1.5");
##
# b(alt)->f
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.2.2");
is($pair[1]->address(), "10.1.1.6");
##
# c->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.1.1");
##
# c->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.1.2");
##
# c->b(alt)
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.2.2");
##
# c->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.1.3");
##
# c->e
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.1.5");
##
# c->f
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.3");
is($pair[1]->address(), "10.1.1.6");
##
# e->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.5");
is($pair[1]->address(), "10.1.1.1");
##
# e->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.5");
is($pair[1]->address(), "10.1.1.2");
##
# e->b(alt)
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.5");
is($pair[1]->address(), "10.1.2.2");
##
# e->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.5");
is($pair[1]->address(), "10.1.1.3");
##
# e->e
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.5");
is($pair[1]->address(), "10.1.1.5");
##
# e->f
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.5");
is($pair[1]->address(), "10.1.1.6");
##
# f->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.6");
is($pair[1]->address(), "10.1.1.1");
##
# f->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.6");
is($pair[1]->address(), "10.1.1.2");
##
# f->b(alt)
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.6");
is($pair[1]->address(), "10.1.2.2");
##
# f->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.6");
is($pair[1]->address(), "10.1.1.3");
##
# f->e
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.6");
is($pair[1]->address(), "10.1.1.5");
##
# f->f
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "10.1.1.6");
is($pair[1]->address(), "10.1.1.6");

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