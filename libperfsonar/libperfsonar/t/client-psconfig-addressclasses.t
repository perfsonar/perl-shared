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
use perfSONAR_PS::Client::PSConfig::Addresses::Address;

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
        "host-a.perfsonar.net": { "address": "anl-pt1-v4.es.net", "host": "host-a" },
        "host-b.perfsonar.net": { "address": "bois-pt1-v4.es.net", "host": "host-b", "tags": ["testbed"]},
        "host-c.perfsonar.net": { "address": "chic-pt1-v4.es.net", "tags": ["testbed"], "host": "host-c" },
        "host-d.perfsonar.net": { 
            "address": "denv-owamp-v4.es.net",
            "_meta": {
                "ifspeed": 1
            }
        },
        "lbl-pt1.es.net": { 
            "address": "lbl-pt1.es.net", 
            "host": "lbl",
            "_meta": {
                "ifspeed": 10
            }
        },
        "sacr-pt1.es.net": { 
            "address": "sacr-pt1.es.net", 
            "tags": [ "testbed" ], 
            "host": "sacr",
            "_meta": {
                "ifspeed": 10
            }
        },
        "chic-pt1-v6.es.net": { "address": "chic-pt1-v6.es.net", "tags": [ "esnet", "testbed" ], "host": "chic" },
        "antg-staging-v4": { "address": "198.128.151.25" },
        "antg-staging-v6": { "address": "2001:400:210:151::25" }
    },
    
    "hosts": {
        "host-a": {
            "tags": [ "testbed" ]
        },
        "host-b": {
            "tags": [ "testbed" ],
            "no-agent": true
        },
        "host-c": {},
        "lbl": {
            "tags": [ "esnet", "testbed" ]
        },
        "sacr": {
            "tags": [ "esnet" ],
            "_meta": {
                "site-display-name": "Sacramento"
            }
        },
        "chic": {}
        
    },
    
    "address-classes": {
        "tag-esnet": { 
            "data-source": {"type": "current-config"},
            "match-filter": {
                "type": "tag",
                "tag": "esnet"
            }
        },
        "tag-testbed": { 
            "data-source": {"type": "current-config"},
            "match-filter": {
                "type": "tag",
                "tag": "testbed"
            }
        },
         "tag-testbed-ra": { 
            "data-source": {"type": "requesting-agent"},
            "match-filter": {
                "type": "tag",
                "tag": "testbed"
            }
        },
        "and-tag": { 
            "data-source": {"type": "current-config"},
            "match-filter": {
                "type": "and",
                "filters": [
                    {
                        "type": "tag",
                        "tag": "esnet"
                    },
                    {
                        "type": "tag",
                        "tag": "testbed"
                    }
                ]
            }
        },
        "or-tag": { 
            "data-source": {"type": "current-config"},
            "match-filter": {
                "type": "or",
                "filters": [
                    {
                        "type": "tag",
                        "tag": "esnet"
                    },
                    {
                        "type": "tag",
                        "tag": "testbed"
                    }
                ]
            }
        },
        "not-addrclass": { 
            "data-source": {"type": "current-config"},
            "match-filter": {
                "type": "not",
                "filter": {
                    "type": "address-class",
                    "class": "tag-esnet"
                }
            }
        },
        "host": { 
            "data-source": {"type": "current-config"},
            "match-filter": {
                "type": "host",
                "tag": "esnet",
                "no-agent": false
            }
        },
        "ipversion": { 
            "data-source": {"type": "current-config"},
            "match-filter": {
                "type": "ip-version",
                "ip-version": 6
            }
        },
        "ipversion-v4": { 
            "data-source": {"type": "current-config"},
            "match-filter": {
                "type": "ip-version",
                "ip-version": 4
            }
        },
        "netmask": { 
            "data-source": {"type": "current-config"},
            "match-filter": {
                "type": "netmask",
                "netmask": "198.129.254.0/24"
            }
        },
        "exclude-tag-esnet": { 
            "data-source": {"type": "current-config"},
            "exclude-filter": {
                "type": "tag",
                "tag": "esnet"
            }
        },
        "host-noagent": { 
            "data-source": {"type": "current-config"},
            "match-filter": {
                "type": "host",
                "no-agent": true
            }
        },
        "host-jq": { 
            "data-source": {"type": "current-config"},
            "match-filter": {
                "type": "host",
                "jq": {
                    "script": "._meta.\"site-display-name\"==\"Sacramento\""
                }
            }
        },
        "jq": { 
            "data-source": {"type": "current-config"},
            "match-filter": {
                "type": "jq",
                "jq": {
                    "script": "._meta.ifspeed==10"
                }
            }
        }
    },
    
    "groups": {
        "example-group-tag-esnet": {
            "type": "mesh",
            "addresses": [
                { "class": "tag-esnet" }
            ]
        },
        "example-group-tag-testbed": {
            "type": "mesh",
            "addresses": [
                { "class": "tag-testbed" },
                { "class": "tag-testbed-ra" }
            ]
        },
        "example-group-and-tag": {
            "type": "mesh",
            "addresses": [
                { "class": "and-tag" }
            ]
        },
        "example-group-or-tag": {
            "type": "mesh",
            "addresses": [
                { "class": "or-tag" }
            ]
        },
        "example-group-not-addrclass": {
            "type": "mesh",
            "addresses": [
                { "class": "not-addrclass" }
            ]
        },
        "example-group-host": {
            "type": "mesh",
            "addresses": [
                { "class": "host" }
            ]
        },
        "example-group-ipversion": {
            "type": "mesh",
            "addresses": [
                { "class": "ipversion" }
            ]
        },
        "example-group-ipversion-v4": {
            "type": "mesh",
            "addresses": [
                { "class": "ipversion-v4" }
            ]
        },
        "example-group-netmask": {
            "type": "mesh",
            "addresses": [
                { "class": "netmask" }
            ]
        },
        "example-group-exclude-tag-esnet": {
            "type": "mesh",
            "addresses": [
                { "class": "exclude-tag-esnet" }
            ]
        },
        "example-group-host-noagent": {
            "type": "disjoint",
            "a-addresses": [
                { "name": "host-a.perfsonar.net" }
            ],
            "b-addresses": [
                { "class": "host-noagent" }
            ]
        },
        "example-group-host-jq": {
            "type": "disjoint",
            "a-addresses": [
                { "name": "host-a.perfsonar.net" }
            ],
            "b-addresses": [
                { "class": "host-jq" }
            ]
        },
        "example-group-jq": {
            "type": "mesh",
            "addresses": [
                { "class": "jq" }
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
        "example-task-tag-esnet": {
            "group": "example-group-tag-esnet",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-tag-testbed": {
            "group": "example-group-tag-testbed",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-and-tag": {
            "group": "example-group-and-tag",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-or-tag": {
            "group": "example-group-or-tag",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-not-addrclass": {
            "group": "example-group-not-addrclass",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-host": {
            "group": "example-group-host",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-ipversion": {
            "group": "example-group-ipversion",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-ipversion-v4": {
            "group": "example-group-ipversion-v4",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-netmask": {
            "group": "example-group-netmask",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-exclude-tag-esnet": {
            "group": "example-group-exclude-tag-esnet",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-host-noagent": {
            "group": "example-group-host-noagent",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-host-jq": {
            "group": "example-group-host-jq",
            "test": "example-test-throughput",
            "schedule": "example-schedule-PT4H",
            "archives": [ "example-archive-central" ]
        },
        "example-task-jq": {
            "group": "example-group-jq",
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

#set requesting agent 
my $ra = new perfSONAR_PS::Client::PSConfig::Addresses::Address();
ok($ra->address("requester.perfsonar.net"));
ok($ra->add_tag("testbed"));
$psconfig->requesting_agent_addresses({"requester.perfsonar.net" => $ra});

########
# Iterate addresses with esnet tag
########
my $tg;
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-tag-esnet'
));
ok($tg->start());

###
# Address classes do not return results in deterministic order, so need to do process
# of elimination
###
my %expected_pairs = (
    "lbl-pt1.es.net=>sacr-pt1.es.net" => 1,
    "lbl-pt1.es.net=>chic-pt1-v6.es.net" => 1,
    "sacr-pt1.es.net=>lbl-pt1.es.net" => 1,
    "sacr-pt1.es.net=>chic-pt1-v6.es.net" => 1,
    "chic-pt1-v6.es.net=>lbl-pt1.es.net" => 1,
    "chic-pt1-v6.es.net=>sacr-pt1.es.net" => 1,
);

#loop through the number of expected pairs
foreach my $i(keys %expected_pairs){
    my @pair;
    ok(@pair = $tg->next());
    is(@pair, 2);
    ok($expected_pairs{$pair[0]->address() . '=>' . $pair[1]->address()});
}

##
# Should be no more
##
#is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate addresses with testbed tag including requesting agent
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-tag-testbed'
));
ok($tg->start());

###
# Address classes do not return results in deterministic order, so need to do process
# of elimination
###
%expected_pairs = (
    "anl-pt1-v4.es.net=>bois-pt1-v4.es.net" => 1,
    "anl-pt1-v4.es.net=>chic-pt1-v4.es.net" => 1,
    "anl-pt1-v4.es.net=>requester.perfsonar.net" => 1,
    "anl-pt1-v4.es.net=>lbl-pt1.es.net" => 1,
    "anl-pt1-v4.es.net=>sacr-pt1.es.net" => 1,
    "anl-pt1-v4.es.net=>chic-pt1-v6.es.net" => 1,
    "bois-pt1-v4.es.net=>anl-pt1-v4.es.net" => 1,
    "bois-pt1-v4.es.net=>chic-pt1-v4.es.net" => 1,
    "bois-pt1-v4.es.net=>requester.perfsonar.net" => 1,
    "bois-pt1-v4.es.net=>lbl-pt1.es.net" => 1,
    "bois-pt1-v4.es.net=>sacr-pt1.es.net" => 1,
    "bois-pt1-v4.es.net=>chic-pt1-v6.es.net" => 1,
    "chic-pt1-v4.es.net=>anl-pt1-v4.es.net" => 1,
    "chic-pt1-v4.es.net=>bois-pt1-v4.es.net" => 1,
    "chic-pt1-v4.es.net=>requester.perfsonar.net" => 1,
    "chic-pt1-v4.es.net=>lbl-pt1.es.net" => 1,
    "chic-pt1-v4.es.net=>sacr-pt1.es.net" => 1,
    "chic-pt1-v4.es.net=>chic-pt1-v6.es.net" => 1,
    "lbl-pt1.es.net=>anl-pt1-v4.es.net" => 1,
    "lbl-pt1.es.net=>bois-pt1-v4.es.net" => 1,
    "lbl-pt1.es.net=>chic-pt1-v4.es.net" => 1,
    "lbl-pt1.es.net=>requester.perfsonar.net" => 1,
    "lbl-pt1.es.net=>sacr-pt1.es.net" => 1,
    "lbl-pt1.es.net=>chic-pt1-v6.es.net" => 1,
    "sacr-pt1.es.net=>anl-pt1-v4.es.net" => 1,
    "sacr-pt1.es.net=>bois-pt1-v4.es.net" => 1,
    "sacr-pt1.es.net=>chic-pt1-v4.es.net" => 1,
    "sacr-pt1.es.net=>requester.perfsonar.net" => 1,
    "sacr-pt1.es.net=>lbl-pt1.es.net" => 1,
    "sacr-pt1.es.net=>chic-pt1-v6.es.net" => 1,
    "chic-pt1-v6.es.net=>anl-pt1-v4.es.net" => 1,
    "chic-pt1-v6.es.net=>bois-pt1-v4.es.net" => 1,
    "chic-pt1-v6.es.net=>chic-pt1-v4.es.net" => 1,
    "chic-pt1-v6.es.net=>requester.perfsonar.net" => 1,
    "chic-pt1-v6.es.net=>lbl-pt1.es.net" => 1,
    "chic-pt1-v6.es.net=>sacr-pt1.es.net" => 1,
    "requester.perfsonar.net=>anl-pt1-v4.es.net" => 1,
    "requester.perfsonar.net=>bois-pt1-v4.es.net" => 1,
    "requester.perfsonar.net=>chic-pt1-v4.es.net" => 1,
    "requester.perfsonar.net=>lbl-pt1.es.net" => 1,
    "requester.perfsonar.net=>sacr-pt1.es.net" => 1,
    "requester.perfsonar.net=>chic-pt1-v6.es.net" => 1
);

#loop through the number of expected pairs
foreach my $i(keys %expected_pairs){
    my @pair;
    ok(@pair = $tg->next());
    is(@pair, 2);
    ok($expected_pairs{$pair[0]->address() . '=>' . $pair[1]->address()});
}

##
# Should be no more
##
#is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate addresses with testbed AND esnet tag
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-and-tag'
));
ok($tg->start());

###
# Address classes do not return results in deterministic order, so need to do process
# of elimination
###
%expected_pairs = (
    "lbl-pt1.es.net=>sacr-pt1.es.net" => 1,
    "lbl-pt1.es.net=>chic-pt1-v6.es.net" => 1,
    "sacr-pt1.es.net=>lbl-pt1.es.net" => 1,
    "sacr-pt1.es.net=>chic-pt1-v6.es.net" => 1,
    "chic-pt1-v6.es.net=>lbl-pt1.es.net" => 1,
    "chic-pt1-v6.es.net=>sacr-pt1.es.net" => 1,
);

#loop through the number of expected pairs
foreach my $i(keys %expected_pairs){
    my @pair;
    ok(@pair = $tg->next());
    is(@pair, 2);
    ok($expected_pairs{$pair[0]->address() . '=>' . $pair[1]->address()});
}

##
# Should be no more
##
#is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate addresses with testbed OR esnet tag
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-or-tag'
));
ok($tg->start());

###
# Address classes do not return results in deterministic order, so need to do process
# of elimination
###
%expected_pairs = (
    "anl-pt1-v4.es.net=>bois-pt1-v4.es.net" => 1,
    "anl-pt1-v4.es.net=>chic-pt1-v4.es.net" => 1,
    "anl-pt1-v4.es.net=>lbl-pt1.es.net" => 1,
    "anl-pt1-v4.es.net=>sacr-pt1.es.net" => 1,
    "anl-pt1-v4.es.net=>chic-pt1-v6.es.net" => 1,
    "bois-pt1-v4.es.net=>anl-pt1-v4.es.net" => 1,
    "bois-pt1-v4.es.net=>chic-pt1-v4.es.net" => 1,
    "bois-pt1-v4.es.net=>lbl-pt1.es.net" => 1,
    "bois-pt1-v4.es.net=>sacr-pt1.es.net" => 1,
    "bois-pt1-v4.es.net=>chic-pt1-v6.es.net" => 1,
    "chic-pt1-v4.es.net=>anl-pt1-v4.es.net" => 1,
    "chic-pt1-v4.es.net=>bois-pt1-v4.es.net" => 1,
    "chic-pt1-v4.es.net=>lbl-pt1.es.net" => 1,
    "chic-pt1-v4.es.net=>sacr-pt1.es.net" => 1,
    "chic-pt1-v4.es.net=>chic-pt1-v6.es.net" => 1,
    "lbl-pt1.es.net=>anl-pt1-v4.es.net" => 1,
    "lbl-pt1.es.net=>bois-pt1-v4.es.net" => 1,
    "lbl-pt1.es.net=>chic-pt1-v4.es.net" => 1,
    "lbl-pt1.es.net=>sacr-pt1.es.net" => 1,
    "lbl-pt1.es.net=>chic-pt1-v6.es.net" => 1,
    "sacr-pt1.es.net=>anl-pt1-v4.es.net" => 1,
    "sacr-pt1.es.net=>bois-pt1-v4.es.net" => 1,
    "sacr-pt1.es.net=>chic-pt1-v4.es.net" => 1,
    "sacr-pt1.es.net=>lbl-pt1.es.net" => 1,
    "sacr-pt1.es.net=>chic-pt1-v6.es.net" => 1,
    "chic-pt1-v6.es.net=>anl-pt1-v4.es.net" => 1,
    "chic-pt1-v6.es.net=>bois-pt1-v4.es.net" => 1,
    "chic-pt1-v6.es.net=>chic-pt1-v4.es.net" => 1,
    "chic-pt1-v6.es.net=>lbl-pt1.es.net" => 1,
    "chic-pt1-v6.es.net=>sacr-pt1.es.net" => 1
);

#loop through the number of expected pairs
foreach my $i(keys %expected_pairs){
    my @pair;
    ok(@pair = $tg->next());
    is(@pair, 2);
    ok($expected_pairs{$pair[0]->address() . '=>' . $pair[1]->address()});
}

##
# Should be no more
##
#is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate addresses with not esnet tag
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-not-addrclass'
));
ok($tg->start());

###
# Address classes do not return results in deterministic order, so need to do process
# of elimination
###
%expected_pairs = (
    "anl-pt1-v4.es.net=>bois-pt1-v4.es.net" => 1,
    "anl-pt1-v4.es.net=>chic-pt1-v4.es.net" => 1,
    "anl-pt1-v4.es.net=>denv-owamp-v4.es.net" => 1,
    "anl-pt1-v4.es.net=>198.128.151.25" => 1,
    "anl-pt1-v4.es.net=>2001:400:210:151::25" => 1,
    "bois-pt1-v4.es.net=>anl-pt1-v4.es.net" => 1,
    "bois-pt1-v4.es.net=>chic-pt1-v4.es.net" => 1,
    "bois-pt1-v4.es.net=>denv-owamp-v4.es.net" => 1,
    "bois-pt1-v4.es.net=>198.128.151.25" => 1,
    "bois-pt1-v4.es.net=>2001:400:210:151::25" => 1,
    "chic-pt1-v4.es.net=>anl-pt1-v4.es.net" => 1,
    "chic-pt1-v4.es.net=>bois-pt1-v4.es.net" => 1,
    "chic-pt1-v4.es.net=>denv-owamp-v4.es.net" => 1,
    "chic-pt1-v4.es.net=>198.128.151.25" => 1,
    "chic-pt1-v4.es.net=>2001:400:210:151::25" => 1,
    "denv-owamp-v4.es.net=>anl-pt1-v4.es.net" => 1,
    "denv-owamp-v4.es.net=>bois-pt1-v4.es.net" => 1,
    "denv-owamp-v4.es.net=>chic-pt1-v4.es.net" => 1,
    "denv-owamp-v4.es.net=>198.128.151.25" => 1,
    "denv-owamp-v4.es.net=>2001:400:210:151::25" => 1,
    "198.128.151.25=>anl-pt1-v4.es.net" => 1,
    "198.128.151.25=>bois-pt1-v4.es.net" => 1,
    "198.128.151.25=>chic-pt1-v4.es.net" => 1,
    "198.128.151.25=>denv-owamp-v4.es.net" => 1,
    "198.128.151.25=>2001:400:210:151::25" => 1,
    "2001:400:210:151::25=>anl-pt1-v4.es.net" => 1,
    "2001:400:210:151::25=>bois-pt1-v4.es.net" => 1,
    "2001:400:210:151::25=>chic-pt1-v4.es.net" => 1,
    "2001:400:210:151::25=>denv-owamp-v4.es.net" => 1,
    "2001:400:210:151::25=>198.128.151.25" => 1,
    
);

#loop through the number of expected pairs
foreach my $i(keys %expected_pairs){
    my @pair;
    ok(@pair = $tg->next());
    is(@pair, 2);
    ok($expected_pairs{$pair[0]->address() . '=>' . $pair[1]->address()});
}

##
# Should be no more
##
#is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate addresses belonging to host
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-host'
));
ok($tg->start());

###
# Address classes do not return results in deterministic order, so need to do process
# of elimination
###
%expected_pairs = (
    "lbl-pt1.es.net=>sacr-pt1.es.net" => 1,
    "sacr-pt1.es.net=>lbl-pt1.es.net" => 1,
);

#loop through the number of expected pairs
foreach my $i(keys %expected_pairs){
    my @pair;
    ok(@pair = $tg->next());
    is(@pair, 2);
    ok($expected_pairs{$pair[0]->address() . '=>' . $pair[1]->address()});
}

##
# Should be no more
##
#is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate addresses that are ipv6 or have AAAA records
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-ipversion'
));
ok($tg->start());

###
# Address classes do not return results in deterministic order, so need to do process
# of elimination
###
%expected_pairs = (
    "chic-pt1-v6.es.net=>sacr-pt1.es.net" => 1,
    "chic-pt1-v6.es.net=>2001:400:210:151::25" => 1,
    "sacr-pt1.es.net=>chic-pt1-v6.es.net" => 1,
    "sacr-pt1.es.net=>2001:400:210:151::25" => 1,
    "2001:400:210:151::25=>chic-pt1-v6.es.net" => 1,
    "2001:400:210:151::25=>sacr-pt1.es.net" => 1,
);

#loop through the number of expected pairs
foreach my $i(keys %expected_pairs){
    my @pair;
    ok(@pair = $tg->next());
    is(@pair, 2);
    ok($expected_pairs{$pair[0]->address() . '=>' . $pair[1]->address()});
}

##
# Should be no more
##
#is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate addresses in subnet 198.129.254.0/24
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-netmask'
));
ok($tg->start());

###
# Address classes do not return results in deterministic order, so need to do process
# of elimination
###
%expected_pairs = (
#    "lbl-pt1.es.net=>sacr-pt1.es.net" => 1,
#    "lbl-pt1.es.net=>bois-pt1-v4.es.net" => 1,
#    "bois-pt1-v4.es.net=>lbl-pt1.es.net" => 1,
    "bois-pt1-v4.es.net=>sacr-pt1.es.net" => 1,
#    "sacr-pt1.es.net=>lbl-pt1.es.net" => 1,
    "sacr-pt1.es.net=>bois-pt1-v4.es.net" => 1,
);

#loop through the number of expected pairs
foreach my $i(keys %expected_pairs){
    my @pair;
    ok(@pair = $tg->next());
    is(@pair, 2);
    ok($expected_pairs{$pair[0]->address() . '=>' . $pair[1]->address()});
}

##
# Should be no more
##
#is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate addresses but exclude those with esnet tag
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-exclude-tag-esnet'
));
ok($tg->start());

###
# Address classes do not return results in deterministic order, so need to do process
# of elimination
###
%expected_pairs = (
    "anl-pt1-v4.es.net=>bois-pt1-v4.es.net" => 1,
    "anl-pt1-v4.es.net=>chic-pt1-v4.es.net" => 1,
    "anl-pt1-v4.es.net=>denv-owamp-v4.es.net" => 1,
    "anl-pt1-v4.es.net=>198.128.151.25" => 1,
    "anl-pt1-v4.es.net=>2001:400:210:151::25" => 1,
    "bois-pt1-v4.es.net=>anl-pt1-v4.es.net" => 1,
    "bois-pt1-v4.es.net=>chic-pt1-v4.es.net" => 1,
    "bois-pt1-v4.es.net=>denv-owamp-v4.es.net" => 1,
    "bois-pt1-v4.es.net=>198.128.151.25" => 1,
    "bois-pt1-v4.es.net=>2001:400:210:151::25" => 1,
    "chic-pt1-v4.es.net=>anl-pt1-v4.es.net" => 1,
    "chic-pt1-v4.es.net=>bois-pt1-v4.es.net" => 1,
    "chic-pt1-v4.es.net=>denv-owamp-v4.es.net" => 1,
    "chic-pt1-v4.es.net=>198.128.151.25" => 1,
    "chic-pt1-v4.es.net=>2001:400:210:151::25" => 1,
    "denv-owamp-v4.es.net=>anl-pt1-v4.es.net" => 1,
    "denv-owamp-v4.es.net=>bois-pt1-v4.es.net" => 1,
    "denv-owamp-v4.es.net=>chic-pt1-v4.es.net" => 1,
    "denv-owamp-v4.es.net=>198.128.151.25" => 1,
    "denv-owamp-v4.es.net=>2001:400:210:151::25" => 1,
    "198.128.151.25=>anl-pt1-v4.es.net" => 1,
    "198.128.151.25=>bois-pt1-v4.es.net" => 1,
    "198.128.151.25=>chic-pt1-v4.es.net" => 1,
    "198.128.151.25=>denv-owamp-v4.es.net" => 1,
    "198.128.151.25=>2001:400:210:151::25" => 1,
    "2001:400:210:151::25=>anl-pt1-v4.es.net" => 1,
    "2001:400:210:151::25=>bois-pt1-v4.es.net" => 1,
    "2001:400:210:151::25=>chic-pt1-v4.es.net" => 1,
    "2001:400:210:151::25=>denv-owamp-v4.es.net" => 1,
    "2001:400:210:151::25=>198.128.151.25" => 1,  
);

#loop through the number of expected pairs
foreach my $i(keys %expected_pairs){
    my @pair;
    ok(@pair = $tg->next());
    is(@pair, 2);
    ok($expected_pairs{$pair[0]->address() . '=>' . $pair[1]->address()});
}

##
# Should be no more
##
#is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate addresses with noagent set in host
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-host-noagent'
));
ok($tg->start());

###
# Address classes do not return results in deterministic order, so need to do process
# of elimination
###
%expected_pairs = (
    "anl-pt1-v4.es.net=>bois-pt1-v4.es.net" => 1,
    "bois-pt1-v4.es.net=>anl-pt1-v4.es.net" => 1,  
);

#loop through the number of expected pairs
foreach my $i(keys %expected_pairs){
    my @pair;
    ok(@pair = $tg->next());
    is(@pair, 2);
    ok($expected_pairs{$pair[0]->address() . '=>' . $pair[1]->address()});
}

##
# Should be no more
##
#is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate addresses with site-display-name Sacraemento as defined by host jq
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-host-jq'
));
ok($tg->start());

###
# Address classes do not return results in deterministic order, so need to do process
# of elimination
###
%expected_pairs = (
    "anl-pt1-v4.es.net=>sacr-pt1.es.net" => 1,
    "sacr-pt1.es.net=>anl-pt1-v4.es.net" => 1,  
);

#loop through the number of expected pairs
foreach my $i(keys %expected_pairs){
    my @pair;
    ok(@pair = $tg->next());
    is(@pair, 2);
    ok($expected_pairs{$pair[0]->address() . '=>' . $pair[1]->address()});
}

##
# Should be no more
##
is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate addresses that match jq looking for ifspeed 10
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-jq'
));
ok($tg->start());

###
# Address classes do not return results in deterministic order, so need to do process
# of elimination
###
%expected_pairs = (
    "lbl-pt1.es.net=>sacr-pt1.es.net" => 1,
    "sacr-pt1.es.net=>lbl-pt1.es.net" => 1,  
);

#loop through the number of expected pairs
foreach my $i(keys %expected_pairs){
    my @pair;
    ok(@pair = $tg->next());
    is(@pair, 2);
    ok($expected_pairs{$pair[0]->address() . '=>' . $pair[1]->address()});
}

##
# Should be no more
##
is($tg->next(), undef);

##
# Stop
##
is($tg->stop(), undef);

########
# Iterate through ipv4 hosts
########
ok($tg = new perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator(
    psconfig => $psconfig,
    task_name => 'example-task-ipversion-v4'
));
ok($tg->start());

###
# Address classes do not return results in deterministic order, so need to do process
# of elimination
###
%expected_pairs = (
    "anl-pt1-v4.es.net=>sacr-pt1.es.net" => 1,
    "anl-pt1-v4.es.net=>198.128.151.25" => 1,  
#    "anl-pt1-v4.es.net=>lbl-pt1.es.net" => 1,
    "anl-pt1-v4.es.net=>bois-pt1-v4.es.net" => 1, 
    "anl-pt1-v4.es.net=>chic-pt1-v4.es.net" => 1, 
    "anl-pt1-v4.es.net=>denv-owamp-v4.es.net" => 1, 
    "anl-pt1-v4.es.net=>sacr-pt1.es.net" => 1,
    "bois-pt1-v4.es.net=>198.128.151.25" => 1,  
#    "bois-pt1-v4.es.net=>lbl-pt1.es.net" => 1,
    "bois-pt1-v4.es.net=>sacr-pt1.es.net" => 1,
    "bois-pt1-v4.es.net=>anl-pt1-v4.es.net" => 1, 
    "bois-pt1-v4.es.net=>chic-pt1-v4.es.net" => 1, 
    "bois-pt1-v4.es.net=>denv-owamp-v4.es.net" => 1, 
    "chic-pt1-v4.es.net=>198.128.151.25" => 1,  
#    "chic-pt1-v4.es.net=>lbl-pt1.es.net" => 1,
    "chic-pt1-v4.es.net=>sacr-pt1.es.net" => 1,
    "chic-pt1-v4.es.net=>anl-pt1-v4.es.net" => 1, 
    "chic-pt1-v4.es.net=>bois-pt1-v4.es.net" => 1, 
    "chic-pt1-v4.es.net=>denv-owamp-v4.es.net" => 1, 
    "denv-owamp-v4.es.net=>198.128.151.25" => 1,  
#    "denv-owamp-v4.es.net=>lbl-pt1.es.net" => 1,
    "denv-owamp-v4.es.net=>anl-pt1-v4.es.net" => 1, 
    "denv-owamp-v4.es.net=>bois-pt1-v4.es.net" => 1, 
    "denv-owamp-v4.es.net=>chic-pt1-v4.es.net" => 1, 
    "denv-owamp-v4.es.net=>sacr-pt1.es.net" => 1,
#    "lbl-pt1.es.net=>sacr-pt1.es.net" => 1,
#    "lbl-pt1.es.net=>198.128.151.25" => 1,  
#    "lbl-pt1.es.net=>anl-pt1-v4.es.net" => 1,
#    "lbl-pt1.es.net=>bois-pt1-v4.es.net" => 1, 
#    "lbl-pt1.es.net=>chic-pt1-v4.es.net" => 1, 
#    "lbl-pt1.es.net=>denv-owamp-v4.es.net" => 1, 
#    "sacr-pt1.es.net=>lbl-pt1.es.net" => 1,
    "sacr-pt1.es.net=>198.128.151.25" => 1,
    "sacr-pt1.es.net=>anl-pt1-v4.es.net" => 1,
    "sacr-pt1.es.net=>bois-pt1-v4.es.net" => 1, 
    "sacr-pt1.es.net=>chic-pt1-v4.es.net" => 1, 
    "sacr-pt1.es.net=>denv-owamp-v4.es.net" => 1, 
#    "198.128.151.25=>lbl-pt1.es.net" => 1,
    "198.128.151.25=>sacr-pt1.es.net" => 1,
    "198.128.151.25=>anl-pt1-v4.es.net" => 1,
    "198.128.151.25=>bois-pt1-v4.es.net" => 1, 
    "198.128.151.25=>chic-pt1-v4.es.net" => 1, 
    "198.128.151.25=>denv-owamp-v4.es.net" => 1, 
);

#loop through the number of expected pairs
foreach my $i(keys %expected_pairs){
    my @pair;
    ok(@pair = $tg->next());
    is(@pair, 2);
    ok($expected_pairs{$pair[0]->address() . '=>' . $pair[1]->address()});
}

##
# Should be no more
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
