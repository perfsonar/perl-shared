use strict;
use warnings;

our $VERSION = 4.1;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More;
use Data::Dumper;

use perfSONAR_PS::Client::PSConfig::Config;
use perfSONAR_PS::Client::PSConfig::Addresses::AddressSpec;
use perfSONAR_PS::Client::PSConfig::Addresses::AddressLabelSpec;
use perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddressSpec;
use perfSONAR_PS::Client::PSConfig::Archive;
use perfSONAR_PS::Client::PSConfig::Schedule;
use perfSONAR_PS::Client::PSConfig::Test;
use perfSONAR_PS::Client::PSConfig::Host;
use perfSONAR_PS::Client::PSConfig::Task;
use perfSONAR_PS::Client::PSConfig::Groups::Disjoint;
use perfSONAR_PS::Client::PSConfig::Groups::List;
use perfSONAR_PS::Client::PSConfig::Groups::Mesh;
use perfSONAR_PS::Client::PSConfig::Groups::ExcludeSelfScope;
use perfSONAR_PS::Client::PSConfig::AddressSelectors::Class;
use perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel;

########
#Create initial config
########
my $psconfig;
ok($psconfig = new perfSONAR_PS::Client::PSConfig::Config(), "unable to create Config object");
is($psconfig->json(), '{}');
is($psconfig->psconfig_meta({'foo'=> 'bar'})->{'foo'}, 'bar');
is($psconfig->psconfig_meta_param('project', 'perfSONAR'), 'perfSONAR');

########
#Test Address types
########
my $psaddr;
ok($psaddr = new perfSONAR_PS::Client::PSConfig::Addresses::AddressSpec(), "unable to create AddressSpec object");
##Test BaseAddressSpec fields
is($psaddr->address("lbl-pt1.es.net"), "lbl-pt1.es.net");
is($psaddr->agent_bind_address("lbl-pt1.es.net"), "lbl-pt1.es.net");
is($psaddr->lead_bind_address("lbl-pt1.es.net"), "lbl-pt1.es.net");
is($psaddr->pscheduler_address("lbl-pt1.es.net"), "lbl-pt1.es.net");
is($psaddr->disabled(1), 1);
is($psaddr->disabled(0), 0);
is($psaddr->no_agent(1), 1);
is($psaddr->no_agent(0), 0);
is($psaddr->context_refs(['ctx1'])->[0], 'ctx1');
ok($psaddr->add_context_ref('ctx2'));
is($psaddr->context_refs()->[1], 'ctx2');
is($psaddr->context_refs()->[1], 'ctx2');
is($psaddr->psconfig_meta({'foo'=> 'bar'})->{'foo'}, 'bar');
is($psaddr->psconfig_meta_param('project', 'perfSONAR'), 'perfSONAR');
##Test AddressLabelSpec fields
my $psaddr_label;
ok($psaddr_label = new perfSONAR_PS::Client::PSConfig::Addresses::AddressLabelSpec(), "unable to create AddressLabelSpec object");
is($psaddr_label->address("2001:400:210:151::25"), "2001:400:210:151::25");
is($psaddr->label("ipv6", $psaddr_label)->address(), "2001:400:210:151::25");
is($psaddr->labels()->{"ipv6"}->address(), "2001:400:210:151::25");
##Test AddressSpec fields
ok($psaddr->add_tag('dev'));
is($psaddr->tags()->[0], 'dev');
### Test RemoteAddressSpec
my $psaddr_remote;
ok($psaddr_remote = new perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddressSpec(), "unable to create RemoteAddressSpec object");
is($psaddr_remote->address("10.0.0.1"), "10.0.0.1");
is($psaddr->remote_address("10.0.0.2", $psaddr_remote)->address(), "10.0.0.1");
is($psaddr->remote_addresses()->{"10.0.0.2"}->address(), "10.0.0.1");
##Test connecting address to config
is($psconfig->addresses({"lbl-pt1.es.net", $psaddr})->{"lbl-pt1.es.net"}->checksum(), $psaddr->checksum());
is($psconfig->address("lbl-pt1.es.net", $psaddr)->checksum(), $psaddr->checksum());

########
#Test disjoint group
########
##Create disjoint group
my $psgrp_disjoint;
ok($psgrp_disjoint = new perfSONAR_PS::Client::PSConfig::Groups::Disjoint());
is($psgrp_disjoint->dimension_count(), 2);
is($psgrp_disjoint->default_address_label(), undef);
is($psgrp_disjoint->default_address_label("ipv6"), "ipv6");
is($psgrp_disjoint->force_bidirectional(0), 0);
is($psgrp_disjoint->force_bidirectional(1), 1);
is($psgrp_disjoint->excludes_self('invalid'), undef);
is($psgrp_disjoint->excludes_self(perfSONAR_PS::Client::PSConfig::Groups::ExcludeSelfScope::HOST), perfSONAR_PS::Client::PSConfig::Groups::ExcludeSelfScope::HOST);
is($psconfig->groups({"disjoint", $psgrp_disjoint})->{"disjoint"}->checksum(), $psgrp_disjoint->checksum());
is($psconfig->group("disjoint", $psgrp_disjoint)->checksum(), $psgrp_disjoint->checksum());
##Excludes
my $excl_ap;
ok($excl_ap = new perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair());
my $excl_addr_sel_nl;
ok($excl_addr_sel_nl = new perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel());
is($excl_addr_sel_nl->name("lbl-pt1.es.net"), "lbl-pt1.es.net");
is($excl_addr_sel_nl->label("ipv6"), "ipv6");
my $excl_addr_sel_nl2;
ok($excl_addr_sel_nl2 = new perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel());
is($excl_addr_sel_nl2->name("sacr-pt1.es.net"), "sacr-pt1.es.net");
is($excl_ap->local_address($excl_addr_sel_nl)->checksum(), $excl_addr_sel_nl->checksum());
my $excl_addr_sel_class;
ok($excl_addr_sel_class = new perfSONAR_PS::Client::PSConfig::AddressSelectors::Class());
is($excl_addr_sel_class->class("example"), "example");
is($excl_ap->target_addresses([$excl_addr_sel_class])->[0]->checksum(), $excl_addr_sel_class->checksum());
ok($excl_ap->add_target_address($excl_addr_sel_nl2));
is($excl_ap->target_addresses()->[1]->checksum(), $excl_addr_sel_nl2->checksum());
ok($psgrp_disjoint->add_exclude($excl_ap));
is($psgrp_disjoint->excludes()->[0]->checksum(), $excl_ap->checksum());
##Disjoint specific
is($psgrp_disjoint->a_addresses([$excl_addr_sel_nl2])->[0]->checksum(), $excl_addr_sel_nl2->checksum());
ok($psgrp_disjoint->add_a_address($excl_addr_sel_nl));
is($psgrp_disjoint->a_addresses()->[1]->checksum(), $excl_addr_sel_nl->checksum());
ok($psgrp_disjoint->add_b_address($excl_addr_sel_nl2));
is($psgrp_disjoint->b_addresses()->[0]->checksum(), $excl_addr_sel_nl2->checksum());
is($psgrp_disjoint->b_addresses([$excl_addr_sel_class])->[0]->checksum(), $excl_addr_sel_class->checksum());

########
#Test Mesh group
########
#can do less because shares lots of code with disjoint
my $psgrp_mesh;
ok($psgrp_mesh = new perfSONAR_PS::Client::PSConfig::Groups::Mesh());
is($psgrp_mesh->dimension_count(), 2);
is($psgrp_mesh->addresses([$excl_addr_sel_nl2])->[0]->checksum(), $excl_addr_sel_nl2->checksum());
ok($psgrp_mesh->add_address($excl_addr_sel_nl));
is($psgrp_mesh->addresses()->[1]->checksum(), $excl_addr_sel_nl->checksum());
is($psconfig->group("mesh", $psgrp_mesh)->checksum(), $psgrp_mesh->checksum());


########
#Test List group
########
#can do less because shares lots of code with disjoint
my $psgrp_list;
ok($psgrp_list = new perfSONAR_PS::Client::PSConfig::Groups::List());
is($psgrp_list->dimension_count(), 1);
is($psgrp_list->addresses([$excl_addr_sel_nl2])->[0]->checksum(), $excl_addr_sel_nl2->checksum());
ok($psgrp_list->add_address($excl_addr_sel_nl));
is($psgrp_list->addresses()->[1]->checksum(), $excl_addr_sel_nl->checksum());
is($psconfig->group("list", $psgrp_list)->checksum(), $psgrp_list->checksum());


########
# Test Archives
########
my $psarchive;
ok($psarchive = new perfSONAR_PS::Client::PSConfig::Archive());
is($psarchive->archiver('esmond'), 'esmond');
is($psarchive->ttl('PT1D'), 'PT1D');
is($psarchive->archiver_data({'_api_key' => 'ABC123'})->{'_api_key'}, 'ABC123');
is($psarchive->archiver_data_param('url', 'https://foo.bar/esmond/perfsonar/archive/'), 'https://foo.bar/esmond/perfsonar/archive/');
is($psarchive->archiver_data_param('_api_key'), 'ABC123');
##Test transform
my $psarchive_jq;
ok($psarchive_jq = new perfSONAR_PS::Client::PSConfig::JQTransform());
is($psarchive_jq->script('.'), '.');
is($psarchive_jq->output_raw(0), 0);
is($psarchive->transform($psarchive_jq)->checksum(), $psarchive_jq->checksum());
##Test connecting archives to config
is($psconfig->archives({"lbl-pt1.es.net", $psarchive})->{"lbl-pt1.es.net"}->checksum(), $psarchive->checksum());
is($psconfig->archive("lbl-pt1.es.net", $psarchive)->checksum(), $psarchive->checksum());

########
# Test Schedules
########
my $psschedule;
ok($psschedule = new perfSONAR_PS::Client::PSConfig::Schedule());
is($psschedule->psconfig_meta({'foo'=> 'bar'})->{'foo'}, 'bar');
is($psschedule->psconfig_meta_param('project', 'perfSONAR'), 'perfSONAR');
is($psschedule->start('2017-10-23T17:56:52+00:00'), '2017-10-23T17:56:52+00:00');
is($psschedule->slip('PT10M'), 'PT10M');
is($psschedule->sliprand(0), 0);
is($psschedule->sliprand(1), 1);
is($psschedule->repeat('PT60M'), 'PT60M');
is($psschedule->until('2017-10-24T17:56:52+00:00'), '2017-10-24T17:56:52+00:00');
is($psschedule->max_runs(24), 24);
##Test connecting schedules to config
is($psconfig->schedules({"example", $psschedule})->{"example"}->checksum(), $psschedule->checksum());
is($psconfig->schedule("example", $psschedule)->checksum(), $psschedule->checksum());


########
# Test Tests
########
my $pstest;
ok($pstest = new perfSONAR_PS::Client::PSConfig::Test());
is($pstest->psconfig_meta({'foo'=> 'bar'})->{'foo'}, 'bar');
is($pstest->psconfig_meta_param('project', 'perfSONAR'), 'perfSONAR');
is($pstest->type('throughput'), 'throughput');
is($pstest->spec({'source'=>'lbl-pt1.es.net'})->{'source'}, 'lbl-pt1.es.net');
is($pstest->spec_param('dest', 'chic-pt1.es.net'), 'chic-pt1.es.net');
##Test connecting tests to config
is($psconfig->tests({"example", $pstest})->{"example"}->checksum(), $pstest->checksum());
is($psconfig->test("example", $pstest)->checksum(), $pstest->checksum());


########
#Test Hosts
########
my $pshost;
ok($pshost = new perfSONAR_PS::Client::PSConfig::Host(), "unable to create Host object");
is($pshost->psconfig_meta({'foo'=> 'bar'})->{'foo'}, 'bar');
is($pshost->psconfig_meta_param('project', 'perfSONAR'), 'perfSONAR');
ok($pshost->add_address_ref('lbl-pt1.es.net'));
is($pshost->address_refs()->[0], 'lbl-pt1.es.net');
ok($pshost->add_tag('dev'));
is($pshost->tags()->[0], 'dev');
ok($pshost->add_archive_ref('lbl-pt1.es.net'));
is($pshost->archive_refs()->[0], 'lbl-pt1.es.net');
is($pshost->site("LBL"), "LBL");
is($pshost->disabled(1), 1);
is($pshost->disabled(0), 0);
is($pshost->no_agent(1), 1);
is($pshost->no_agent(0), 0);
##Test connecting hosts to config
is($psconfig->hosts({"lbl-pt1.es.net", $pshost})->{"lbl-pt1.es.net"}->checksum(), $pshost->checksum());
is($psconfig->host("lbl-pt1.es.net", $pshost)->checksum(), $pshost->checksum());


########
# Test Contexts
########
my $pscontext;
ok($pscontext = new perfSONAR_PS::Client::PSConfig::Context());
is($pscontext->context('linux-namespace'), 'linux-namespace');
is($pscontext->context_data({'foo' => 'bar'})->{'foo'}, 'bar');
is($pscontext->context_data_param('namespace', 'foobar'), 'foobar');
is($pscontext->context_data_param('namespace'), 'foobar');
##Test connecting contexts to config
is($psconfig->contexts({"ctx1", $pscontext})->{"ctx1"}->checksum(), $pscontext->checksum());
is($psconfig->context("ctx1", $pscontext)->checksum(), $pscontext->checksum());

########
#Test tasks
########
my $pstask;
ok($pstask = new perfSONAR_PS::Client::PSConfig::Task(), "unable to create task object");
is($pstask->psconfig_meta({'foo'=> 'bar'})->{'foo'}, 'bar');
is($pstask->psconfig_meta_param('project', 'perfSONAR'), 'perfSONAR');
is($pstask->group_ref("mesh"), "mesh");
is($pstask->test_ref("example"), "example");
is($pstask->schedule_ref("example"), "example");
ok($pstask->add_tool('iperf3'));
is($pstask->tools()->[0], 'iperf3');
ok($pstask->add_subtask_ref('sub1'));
is($pstask->subtask_refs()->[0], 'sub1');
ok($pstask->add_archive_ref('lbl-pt1.es.net'));
is($pstask->archive_refs()->[0], 'lbl-pt1.es.net');
is($pstask->disabled(1), 1);
is($pstask->disabled(0), 0);
is($pstask->reference({'foo' => 'bar'})->{'foo'}, 'bar');
is($pstask->reference_param('stuff', 'foobar'), 'foobar');
is($pstask->reference_param('stuff'), 'foobar');
##Test connecting tasks to config
is($psconfig->tasks({"task1", $pstask})->{"task1"}->checksum(), $pstask->checksum());
is($psconfig->task("task1", $pstask)->checksum(), $pstask->checksum());

########
#Test additional utilities - clears out JSON
########
is(@{$psaddr->label_names()}, 1);
ok($psaddr->remove_label("ipv6"));
is(@{$psaddr->label_names()}, 0);
ok($psaddr->remove_labels());
ok(!exists $psaddr->data()->{'labels'});

is(@{$psaddr->remote_address_names()}, 1);
ok($psaddr->remove_remote_address("10.0.0.2"));
is(@{$psaddr->remote_address_names()}, 0);
ok($psaddr->remove_remote_addresses());
ok(!exists $psaddr->data()->{'remote_addresses'});

is(@{$psconfig->address_names()}, 1);
ok($psconfig->remove_address("lbl-pt1.es.net"));
is(@{$psconfig->address_names()}, 0);
ok($psconfig->remove_addresses());
ok(!exists $psconfig->data()->{'addresses'});

is(@{$psconfig->archive_names()}, 1);
ok($psconfig->remove_archive("lbl-pt1.es.net"));
is(@{$psconfig->archive_names()}, 0);
ok($psconfig->remove_archives());
ok(!exists $psconfig->data()->{'archives'});

is(@{$psconfig->context_names()}, 1);
ok($psconfig->remove_context("ctx1"));
is(@{$psconfig->context_names()}, 0);
ok($psconfig->remove_contexts());
ok(!exists $psconfig->data()->{'contexts'});

is(@{$psconfig->group_names()}, 3);
ok($psconfig->remove_group("disjoint"));
is(@{$psconfig->group_names()}, 2);
ok($psconfig->remove_groups());
ok(!exists $psconfig->data()->{'groups'});

is(@{$psconfig->host_names()}, 1);
ok($psconfig->remove_host("lbl-pt1.es.net"));
is(@{$psconfig->host_names()}, 0);
ok($psconfig->remove_hosts());
ok(!exists $psconfig->data()->{'hosts'});

is(@{$psconfig->schedule_names()}, 1);
ok($psconfig->remove_schedule("example"));
is(@{$psconfig->schedule_names()}, 0);
ok($psconfig->remove_schedules());
ok(!exists $psconfig->data()->{'schedules'});

is(@{$psconfig->task_names()}, 1);
ok($psconfig->remove_task("task1"));
is(@{$psconfig->task_names()}, 0);
ok($psconfig->remove_tasks());
ok(!exists $psconfig->data()->{'tasks'});

is(@{$psconfig->test_names()}, 1);
ok($psconfig->remove_test("example"));
is(@{$psconfig->test_names()}, 0);
ok($psconfig->remove_tests());
ok(!exists $psconfig->data()->{'tests'});

ok($psconfig->remove_psconfig_meta_param("project"));
ok($psconfig->remove_psconfig_meta());
ok(!exists $psconfig->data()->{'_meta'});


##################################################################
#TODO: Delete below
diag($psconfig->json({'pretty' => 1}));
##################################################################

########
#finish testing
########
done_testing();
