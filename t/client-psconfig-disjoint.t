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
        "host-a.perfsonar.net": { "address": "host-a.perfsonar.net" },
        "host-b.perfsonar.net": { "address": "host-b.perfsonar.net" },
        "host-c.perfsonar.net": { "address": "host-c.perfsonar.net" },
        "host-d.perfsonar.net": { "address": "host-d.perfsonar.net" },
        "host-e.perfsonar.net": { "address": "host-e.perfsonar.net" },
        "host-f.perfsonar.net": { "address": "host-f.perfsonar.net" },
        "host-g.perfsonar.net": { "address": "host-f.perfsonar.net", "disabled": true },
        "host-h.perfsonar.net": { "address": "host-f.perfsonar.net", "host": "host-h"  }
    },
    
    "hosts": {
        "host-h": {
            "disabled": true
        }
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
        },
        "example-group-disjoint-uni": {
            "type": "disjoint",
            "unidirectional": true,
            "a-addresses": [
                { "name": "host-a.perfsonar.net" }
            ],
            "b-addresses": [
                { "name": "host-a.perfsonar.net" },
                { "name": "host-b.perfsonar.net" },
                { "name": "host-c.perfsonar.net" }
            ]
        },
        "example-group-disjoint-exclude": {
            "type": "disjoint",
            "a-addresses": [
                { "name": "host-a.perfsonar.net" },
                { "name": "host-b.perfsonar.net" },
                { "name": "host-c.perfsonar.net" }
            ],
            "b-addresses": [
                { "name": "host-d.perfsonar.net" },
                { "name": "host-e.perfsonar.net" },
                { "name": "host-f.perfsonar.net" },
                { "name": "host-g.perfsonar.net" },
                { "name": "host-h.perfsonar.net" }
            ],
            "excludes": [
                {
                    "local-address": {"name": "host-a.perfsonar.net"},
                    "target-addresses": [
                        {"name": "host-f.perfsonar.net"}
                    ]
                }
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
        },
        "example-task-throughput-uni": {
            "group": "example-group-disjoint-uni",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-throughput-exclude": {
            "group": "example-group-disjoint-exclude",
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
# Iterate through bidirectional disjoint setup
########
my $tg;
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-throughput'
));
ok($tg->start());
my $group;
ok($group = $tg->group());
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
# No more
##
is($tg->next(), undef);

##
# Edge cases for various methods
##
is($tg->is_disabled(),undef);
is($group->a_address(0)->name(), "host-a.perfsonar.net");
is($group->b_address(2)->name(), "host-c.perfsonar.net");
is($group->dimension_size(),undef);
is($group->dimension_size(3),undef);
is($group->dimension(),undef);
is($group->dimension(3),undef);
my @dimension;
ok(@dimension = @{$group->dimension(0)});
is(@dimension,4);
is($dimension[0]->name(),"host-a.perfsonar.net");
is($dimension[1]->name(),"host-a.perfsonar.net");
is($dimension[2]->name(),"host-b.perfsonar.net");
is($dimension[3]->name(),"host-c.perfsonar.net");
ok(@dimension = @{$group->dimension(1)});
is(@dimension,4);
is($dimension[0]->name(),"host-a.perfsonar.net");
is($dimension[1]->name(),"host-a.perfsonar.net");
is($dimension[2]->name(),"host-b.perfsonar.net");
is($dimension[3]->name(),"host-c.perfsonar.net");
is($group->is_excluded_selectors(), undef);
is($group->is_excluded_selectors("foo"), undef);
is($group->is_excluded_selectors(["foo"]), undef);
is($group->is_excluded_selectors(["foo"]), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate through unidirectional disjoint setup
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-throughput-uni'
));
ok($tg->start());
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
# No more
##
is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate through disjoint setup with excludes
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-throughput-exclude'
));
ok($tg->start());
##
# a->d
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-a.perfsonar.net");
is($pair[1]->address(), "host-d.perfsonar.net");
##
# a->e
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-a.perfsonar.net");
is($pair[1]->address(), "host-e.perfsonar.net");
##
# b->d
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-b.perfsonar.net");
is($pair[1]->address(), "host-d.perfsonar.net");
##
# b->e
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-b.perfsonar.net");
is($pair[1]->address(), "host-e.perfsonar.net");
##
# b->f
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-b.perfsonar.net");
is($pair[1]->address(), "host-f.perfsonar.net");
##
# c->d
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-c.perfsonar.net");
is($pair[1]->address(), "host-d.perfsonar.net");
##
# c->e
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-c.perfsonar.net");
is($pair[1]->address(), "host-e.perfsonar.net");
##
# c->f
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-c.perfsonar.net");
is($pair[1]->address(), "host-f.perfsonar.net");
##
# d->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-d.perfsonar.net");
is($pair[1]->address(), "host-a.perfsonar.net");
##
# d->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-d.perfsonar.net");
is($pair[1]->address(), "host-b.perfsonar.net");
##
# d->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-d.perfsonar.net");
is($pair[1]->address(), "host-c.perfsonar.net");
##
# e->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-e.perfsonar.net");
is($pair[1]->address(), "host-a.perfsonar.net");
##
# e->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-e.perfsonar.net");
is($pair[1]->address(), "host-b.perfsonar.net");
##
# e->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-e.perfsonar.net");
is($pair[1]->address(), "host-c.perfsonar.net");
##
# f->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-f.perfsonar.net");
is($pair[1]->address(), "host-a.perfsonar.net");
##
# f->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-f.perfsonar.net");
is($pair[1]->address(), "host-b.perfsonar.net");
##
# f->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-f.perfsonar.net");
is($pair[1]->address(), "host-c.perfsonar.net");

##
# No more
##
is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
#finish testing
########
done_testing();