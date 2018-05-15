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
        "archive-lsvn": {
            "archiver": "esmond",
            "data": {
                "url": "https://lsvn-pt1.es.net/esmond/perfsonar/archive/",
                "measurement-agent": "{% scheduled_by_address %}"
            }
        },
        "archive-ga": {
            "archiver": "esmond",
            "data": {
                "url": "https://ga-pt1.es.net/esmond/perfsonar/archive/",
                "measurement-agent": "{% scheduled_by_address %}"
            }
        },
        "archive-bost": {
            "archiver": "esmond",
            "data": {
                "url": "https://bost-pt1.es.net/esmond/perfsonar/archive/",
                "measurement-agent": "{% scheduled_by_address %}"
            }
        },
        "archive-amst": {
            "archiver": "esmond",
            "data": {
                "url": "https://amst-pt1.es.net/esmond/perfsonar/archive/",
                "measurement-agent": "{% scheduled_by_address %}"
            }
        },
        "archive-newy": {
            "archiver": "esmond",
            "data": {
                "url": "https://newy-pt1.es.net/esmond/perfsonar/archive/",
                "measurement-agent": "{% scheduled_by_address %}"
            }
        },
        "archive-lond": {
            "archiver": "esmond",
            "data": {
                "url": "https://lond-pt1.es.net/esmond/perfsonar/archive/",
                "measurement-agent": "{% scheduled_by_address %}"
            }
        },
        "archive-aofa": {
            "archiver": "esmond",
            "data": {
                "url": "https://aofa-pt1.es.net/esmond/perfsonar/archive/",
                "measurement-agent": "{% scheduled_by_address %}"
            }
        },
        "archive-wash": {
            "archiver": "esmond",
            "data": {
                "url": "https://wash-pt1.es.net/esmond/perfsonar/archive/",
                "measurement-agent": "{% scheduled_by_address %}"
            }
        },
        "archive-cern-513": {
            "archiver": "esmond",
            "data": {
                "url": "https://cern-513-pt1.es.net/esmond/perfsonar/archive/",
                "measurement-agent": "{% scheduled_by_address %}"
            }
        }
    },
    
    "addresses": {
        "lsvn-pt1": { 
            "address": "lsvn-pt1.es.net",
            "host": "lsvn-pt1.es.net",
            "remote-addresses": {
                "ga-pt1.es.net": {
                    "labels": {
                        "backup-path": {
                            "address": "192.168.14.33"
                        }
                    }
                },
                "amst-pt1.es.net": {
                    "address": "198.129.254.94",
                    "labels": {
                        "do-not-use": {
                            "address": "192.168.14.33"
                        }
                    }
                }
            }
        },
        "lsvn-owamp.es.net": { 
            "address": "lsvn-owamp.es.net",
            "host": "lsvn-pt1.es.net",
            "remote-addresses": {
                "ga-owamp.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.37" 
                        }
                    }
                }
            }
        },
        "ga-pt1.es.net": { 
            "address": "ga-pt1.es.net",
            "host": "ga-pt1.es.net",
            "remote-addresses": {
                "lsvn-pt1": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.34" 
                        }
                    }
                }
            }
        },
        "ga-owamp.es.net": { 
            "address": "ga-owamp.es.net",
            "host": "ga-pt1.es.net",
            "remote-addresses": {
                "lsvn-owamp.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.38" 
                        }
                    }
                }
            }
        },
        "bost-pt1.es.net": { 
            "address": "bost-pt1.es.net",
            "host": "bost-pt1.es.net",
            "remote-addresses": {
                "amst-pt1.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.1" 
                        }
                    }
                }
            }
        },
        "bost-owamp.es.net": { 
            "address": "bost-owamp.es.net",
            "host": "bost-pt1.es.net",
            "remote-addresses": {
                "amst-owamp.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.5" 
                        }
                    }
                }
            }
        },
        "amst-pt1.es.net": { 
            "address": "amst-pt1.es.net",
            "host": "amst-pt1.es.net",
            "remote-addresses": {
                "bost-pt1.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.2" 
                        }
                    }
                }
            }
        },
        "amst-owamp.es.net": { 
            "address": "amst-owamp.es.net",
            "host": "amst-pt1.es.net",
            "remote-addresses": {
                "bost-owamp.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.6" 
                        }
                    }
                }
            }
        },
        "newy-pt1.es.net": { 
            "address": "newy-pt1.es.net",
            "host": "newy-pt1.es.net",
            "remote-addresses": {
                "lond-pt1.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.9" 
                        }
                    }
                }
            }
        },
        "newy-owamp.es.net": { 
            "address": "newy-owamp.es.net",
            "host": "newy-pt1.es.net",
            "remote-addresses": {
                "lond-owamp.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.13" 
                        }
                    }
                }
            }
        },
        "lond-pt1.es.net": { 
            "address": "lond-pt1.es.net",
            "host": "lond-pt1.es.net",
            "remote-addresses": {
                "newy-pt1.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.10" 
                        }
                    }
                },
                "aofa-pt1.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.18" 
                        }
                    }
                }
            }
        },
        "lond-owamp.es.net": { 
            "address": "lond-owamp.es.net",
            "host": "lond-pt1.es.net",
            "remote-addresses": {
                "newy-owamp.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.14" 
                        }
                    }
                },
                "aofa-owamp.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.22" 
                        }
                    }
                }
            }
        },
        "aofa-pt1.es.net": { 
            "address": "aofa-pt1.es.net",
            "host": "aofa-pt1.es.net",
            "remote-addresses": {
                "lond-pt1.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.17" 
                        }
                    }
                }
            }
        },
        "aofa-owamp.es.net": { 
            "address": "aofa-owamp.es.net",
            "host": "aofa-pt1.es.net",
            "remote-addresses": {
                "lond-owamp.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.21" 
                        }
                    }
                }
            }
        },
        "wash-pt1.es.net": { 
            "address": "wash-pt1.es.net",
            "host": "wash-pt1.es.net",
            "remote-addresses": {
                "cern-513-pt1.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.25" 
                        }
                    }
                }
            }
        },
        "wash-owamp.es.net": { 
            "address": "wash-owamp.es.net",
            "host": "wash-pt1.es.net",
            "remote-addresses": {
                "cern-513-owamp.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.29" 
                        }
                    }
                }
            }
        },
        "cern-513-pt1.es.net": { 
            "address": "cern-513-pt1.es.net",
            "host": "cern-513-pt1.es.net",
            "remote-addresses": {
                "wash-pt1.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.26" 
                        }
                    }
                }
            }
        },
        "cern-513-owamp.es.net": { 
            "address": "cern-513-owamp.es.net",
            "host": "cern-513-pt1.es.net",
            "remote-addresses": {
                "wash-owamp.es.net": { 
                    "labels": {
                        "backup-path": { 
                            "address": "192.168.14.30" 
                        }
                    }
                }
            }
        }
    },
    
    "hosts": {
        "lsvn-pt1.es.net": {
            "archives": [ "archive-lsvn" ]
        },
        "ga-pt1.es.net": {
            "archives": [ "archive-ga" ]
        },
        "bost-pt1.es.net": {
            "archives": [ "archive-bost" ]
        },
        "amst-pt1.es.net": {
            "archives": [ "archive-amst" ]
        },
        "newy-pt1.es.net": {
            "archives": [ "archive-newy" ]
        },
        "lond-pt1.es.net": {
            "archives": [ "archive-lond" ]
        },
        "aofa-pt1.es.net": {
            "archives": [ "archive-aofa" ]
        },
        "wash-pt1.es.net": {
            "archives": [ "archive-wash" ]
        },
        "cern-513-pt1.es.net": {
            "archives": [ "archive-cern-513" ]
        }
    },
    
    "groups": {
        "backup-paths-pt": {
            "type": "disjoint",
            "default-address-label": "backup-path",
            "a-addresses": [
                { "name": "lsvn-pt1" },
                { "name": "bost-pt1.es.net" },
                { "name": "newy-pt1.es.net" },
                { "name": "aofa-pt1.es.net" },
                { "name": "wash-pt1.es.net" }
            ],
            "b-addresses": [
                { "name": "ga-pt1.es.net" },
                { "name": "amst-pt1.es.net" },
                { "name": "lond-pt1.es.net" },
                { "name": "cern-513-pt1.es.net" }
            ]
        },
        "backup-paths-owamp": {
            "type": "disjoint",
            "default-address-label": "backup-path",
            "a-addresses": [
                { "name": "lsvn-owamp.es.net" },
                { "name": "bost-owamp.es.net" },
                { "name": "newy-owamp.es.net" },
                { "name": "aofa-owamp.es.net" },
                { "name": "wash-owamp.es.net" }
            ],
            "b-addresses": [
                { "name": "ga-owamp.es.net" },
                { "name": "amst-owamp.es.net" },
                { "name": "lond-owamp.es.net" },
                { "name": "cern-513-owamp.es.net" }
            ]
        }
    },
    
    "tests": {
        "throughput-default": {
            "type": "throughput",
            "spec": {
                "source": "{% address[0] %}",
                "dest": "{% address[1] %}",
                "duration": "PT30S"
            }
        },
        "latencybg-default": {
            "type": "latencybg",
            "spec": {
                "source": "{% address[0] %}",
                "dest": "{% address[1] %}",
                "packet-interval": 0.1,
                "packet-count": 600
            }
        }
    },
    
    "schedules": {
        "repeat-PT4H": {
            "repeat": "PT4H",
            "sliprand": true,
            "slip": "PT4H"
        }
    },
    
    "tasks": {
        "backup-path-throughput": {
            "group": "backup-paths-pt",
            "test": "throughput-default",
            "schedule": "repeat-PT4H"
        },
        "backup-path-latencybg": {
            "group": "backup-paths-owamp",
            "test": "latencybg-default"
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
    task_name => 'backup-path-throughput'
));
ok($tg->start());

my @pair;
##
# lsvn->ga
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "192.168.14.33");
is($pair[1]->address(), "192.168.14.34");
##
# bost->amst
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "192.168.14.1");
is($pair[1]->address(), "192.168.14.2");
##
# newy->lond
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "192.168.14.9");
is($pair[1]->address(), "192.168.14.10");
##
# aofa->lond
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "192.168.14.17");
is($pair[1]->address(), "192.168.14.18");
##
# wash->cern-513
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "192.168.14.25");
is($pair[1]->address(), "192.168.14.26");
##
# ga->lsvn
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "192.168.14.34");
is($pair[1]->address(), "192.168.14.33");
##
# amst->bost
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "192.168.14.2");
is($pair[1]->address(), "192.168.14.1");
##
# lond->newy
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "192.168.14.10");
is($pair[1]->address(), "192.168.14.9");
##
# lond->aofa
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "192.168.14.18");
is($pair[1]->address(), "192.168.14.17");
##
# cern-513->wash
##
ok(@pair = $tg->next());
is(@pair, 2);
is($pair[0]->address(), "192.168.14.26");
is($pair[1]->address(), "192.168.14.25");

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