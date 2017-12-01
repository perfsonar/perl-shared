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
        "host-c.perfsonar.net": { "address": "host-c.perfsonar.net" }
    },
    
    "groups": {
         "example-group-mesh": {
            "type": "mesh",
            "addresses": [
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
# b->c
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-b.perfsonar.net");
is($pair[1]->address(), "host-c.perfsonar.net");
##
# c->a
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-c.perfsonar.net");
is($pair[1]->address(), "host-a.perfsonar.net");
##
# c->b
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "host-c.perfsonar.net");
is($pair[1]->address(), "host-b.perfsonar.net");

##
# No more
##
is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);


##
# Edge cases for various methods
##
is($group->dimension_size(),undef);
is($group->dimension_size(3),undef);
is($group->dimension(),undef);
is($group->dimension(3),undef);
my @dimension;
ok(@dimension = @{$group->dimension(0)});
is(@dimension,3);
is($dimension[0]->name(),"host-a.perfsonar.net");
is($dimension[1]->name(),"host-b.perfsonar.net");
is($dimension[2]->name(),"host-c.perfsonar.net");
ok(@dimension = @{$group->dimension(1)});
is(@dimension,3);
is($dimension[0]->name(),"host-a.perfsonar.net");
is($dimension[1]->name(),"host-b.perfsonar.net");
is($dimension[2]->name(),"host-c.perfsonar.net");
is($group->select_addresses(), undef);
is($group->select_addresses("foo"), undef);
is($group->select_addresses(["foo"]), undef);

########
#finish testing
########
done_testing();