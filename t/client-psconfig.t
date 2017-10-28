use strict;
use warnings;

our $VERSION = 4.1;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More;
use Data::Dumper;

use perfSONAR_PS::Client::PSConfig::Config;
use perfSONAR_PS::Client::PSConfig::Addresses::Address;
use perfSONAR_PS::Client::PSConfig::Addresses::AddressLabel;
use perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddress;
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
use perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::CurrentConfig;
use perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::RequestingAgent;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::AddressClass;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::And;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Host;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::IPVersion;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Netmask;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Not;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Or;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Tag;
use perfSONAR_PS::Client::PSConfig::AddressClasses::AddressClass;
use perfSONAR_PS::Client::PSConfig::Subtask;

########
#Create initial config
########
my $psconfig;
ok($psconfig = new perfSONAR_PS::Client::PSConfig::Config());
is($psconfig->json(), '{}');
is($psconfig->psconfig_meta({'foo'=> 'bar'})->{'foo'}, 'bar');
is($psconfig->psconfig_meta_param('project', 'perfSONAR'), 'perfSONAR');
is($psconfig->psconfig_meta_param(), undef); #fail - null key
is($psconfig->psconfig_meta_param('blah'), undef); #fail - null val

########
#Test Address types
########
my $psaddr;
ok($psaddr = new perfSONAR_PS::Client::PSConfig::Addresses::Address());
##Test BaseAddress fields
is($psaddr->address("foo#bar"), undef);
is($psaddr->address("198.129.254.30"), "198.129.254.30");
is($psaddr->address("2001:400:201:1150::3"), "2001:400:201:1150::3");
is($psaddr->address("lbl-pt1.es.net"), "lbl-pt1.es.net");
## _field_name edge cases
is($psaddr->host_ref("lbl-pt1\@es.net"), undef);
####
is($psaddr->host_ref("lbl-pt1.es.net"), "lbl-pt1.es.net");
is($psaddr->agent_bind_address("lbl-pt1.es.net"), "lbl-pt1.es.net");
is($psaddr->lead_bind_address("lbl-pt1.es.net"), "lbl-pt1.es.net");
##test _field_urlhostport edge cases
is($psaddr->pscheduler_address("foo#bar"), undef);
is($psaddr->pscheduler_address("[::1]:443"), "[::1]:443");
#####
is($psaddr->pscheduler_address("lbl-pt1.es.net"), "lbl-pt1.es.net");
is($psaddr->pscheduler_address(), "lbl-pt1.es.net");
is($psaddr->disabled(), 0);
is($psaddr->disabled('blah'), undef);
is($psaddr->disabled(1), 1);
is($psaddr->disabled(0), 0);
is($psaddr->disabled(), 0);
is($psaddr->no_agent(1), 1);
is($psaddr->no_agent(0), 0);
is($psaddr->context_refs(['ctx1'])->[0], 'ctx1');
is($psaddr->context_refs(['foo@bar']), undef); #fail
is($psaddr->context_refs({}), undef); #fail
ok($psaddr->add_context_ref('ctx2'));
is($psaddr->add_context_ref('foo@bar'), undef);
is($psaddr->context_refs()->[1], 'ctx2');
is($psaddr->context_refs()->[1], 'ctx2');
is($psaddr->psconfig_meta({'foo'=> 'bar'})->{'foo'}, 'bar');
is($psaddr->psconfig_meta_param('project', 'perfSONAR'), 'perfSONAR');
##Test AddressLabel fields
my $psaddr_label;
ok($psaddr_label = new perfSONAR_PS::Client::PSConfig::Addresses::AddressLabel());
is($psaddr_label->address("2001:400:210:151::25"), "2001:400:210:151::25");
is($psaddr->label("ipv6", $psaddr_label)->address(), "2001:400:210:151::25");
is($psaddr->label("ipv6")->address(), "2001:400:210:151::25");
is($psaddr->label("blah"), undef); # fail - no label
is($psaddr->label(), undef); # fail - null label
is($psaddr->labels()->{"ipv6"}->address(), "2001:400:210:151::25");
is($psaddr->labels({"ipv6" => $psaddr_label})->{"ipv6"}->address(), "2001:400:210:151::25");
is($psaddr->labels("blah"), undef);
is($psaddr->labels({"foo" => "bar"}), undef);

##Test Address fields
ok($psaddr->add_tag('dev'));
is($psaddr->add_tag(), undef);
is($psaddr->tags()->[0], 'dev');
### Test RemoteAddress
my $psaddr_remote;
ok($psaddr_remote = new perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddress());
is($psaddr_remote->address("10.0.0.1"), "10.0.0.1");
is($psaddr->remote_address("10.0.0.2"), undef); #fail - not added yet
is($psaddr->remote_address("10.0.0.2", $psaddr_remote)->address(), "10.0.0.1");
is($psaddr->remote_address(), undef); #fail
is($psaddr->remote_address("bah"), undef); #fail
is($psaddr->remote_addresses()->{"10.0.0.2"}->address(), "10.0.0.1");
is($psaddr->remote_addresses({"10.0.0.2" => $psaddr_remote})->{"10.0.0.2"}->address(), "10.0.0.1");

##Test connecting address to config
is($psconfig->address("blah"), undef);#fail - map does not exist
is(keys %{$psconfig->addresses()}, 0);
is($psconfig->addresses({"lbl-pt1.es.net", $psaddr})->{"lbl-pt1.es.net"}->checksum(), $psaddr->checksum());
is($psconfig->address("lbl-pt1.es.net", $psaddr)->checksum(), $psaddr->checksum());
is($psconfig->address(), undef); #fail - no key specified
is($psconfig->address("blah"), undef);#fail - key does not exist

########
#Test Address classes
########
##Create data sources
my $psaddrclass_ds_cc;
ok($psaddrclass_ds_cc = new perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::CurrentConfig());
my $psaddrclass_ds_ra;
ok($psaddrclass_ds_ra = new perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::RequestingAgent());
my $ds_factory;
ok($ds_factory = new perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::DataSourceFactory());
is($ds_factory->build({}), undef);
is($ds_factory->build({'type'=>'blah'}), undef);

##Create filters
###Factory edge cases
my $filter_factory;
ok($filter_factory = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::FilterFactory());
is($filter_factory->build({}), undef);
is($filter_factory->build({'type'=>'blah'}), undef);
###AddressClass filter
my $psaddrclass_filter_addrclass;
ok($psaddrclass_filter_addrclass = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::AddressClass());
is($psaddrclass_filter_addrclass->class('example'), 'example');
is($psaddrclass_filter_addrclass->class(), 'example');
###Host filter
my $psaddrclass_filter_host;
ok($psaddrclass_filter_host = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Host());
is($psaddrclass_filter_host->site('site1'), 'site1');
is($psaddrclass_filter_host->tag('tag1'), 'tag1');
is($psaddrclass_filter_host->tag('tag1'), 'tag1');
is($psaddrclass_filter_host->no_agent(1), 1);
is($psaddrclass_filter_host->no_agent(0), 0);
###IPVersion filter
my $psaddrclass_filter_ipv;
ok($psaddrclass_filter_ipv = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::IPVersion());
is($psaddrclass_filter_ipv->ip_version(), undef);
is($psaddrclass_filter_ipv->ip_version(5), undef);
is($psaddrclass_filter_ipv->ip_version(4), 4);
is($psaddrclass_filter_ipv->ip_version(6), 6);
###Netmask filter
my $psaddrclass_filter_netmask;
ok($psaddrclass_filter_netmask = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Netmask());
is($psaddrclass_filter_netmask->netmask('blah'), undef);
is($psaddrclass_filter_netmask->netmask('2620:0:2d0:2df::7/64'), '2620:0:2d0:2df::7/64');
is($psaddrclass_filter_netmask->netmask('10.0.0.0/24'), '10.0.0.0/24');
is($psaddrclass_filter_netmask->netmask(), '10.0.0.0/24');
###Tag filter
my $psaddrclass_filter_tag;
ok($psaddrclass_filter_tag = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Tag());
is($psaddrclass_filter_tag->tag('tag2'), 'tag2');
###Not filter
my $psaddrclass_filter_not;
ok($psaddrclass_filter_not = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Not());
is($psaddrclass_filter_not->filter($psaddrclass_filter_tag)->checksum(), $psaddrclass_filter_tag->checksum());
isa_ok($psaddrclass_filter_not->filter(), 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Tag');
###Or filter
my $psaddrclass_filter_or;
ok($psaddrclass_filter_or = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Or());
ok($psaddrclass_filter_or->add_filter($psaddrclass_filter_addrclass));
is($psaddrclass_filter_or->filters([$psaddrclass_filter_addrclass])->[0]->checksum(), $psaddrclass_filter_addrclass->checksum());
is($psaddrclass_filter_or->add_filter(), undef);
ok($psaddrclass_filter_or->add_filter($psaddrclass_filter_host));
my $psaddrclass_filter_or_filters;
ok($psaddrclass_filter_or_filters = $psaddrclass_filter_or->filters());
is(@{$psaddrclass_filter_or_filters}, 2);
isa_ok($psaddrclass_filter_or_filters->[0], 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::AddressClass');
isa_ok($psaddrclass_filter_or_filters->[1], 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Host');
###And filter
my $psaddrclass_filter_and1;
ok($psaddrclass_filter_and1 = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::And());
is(@{$psaddrclass_filter_and1->filters()}, 0);
ok($psaddrclass_filter_and1->add_filter($psaddrclass_filter_ipv));
ok($psaddrclass_filter_and1->add_filter($psaddrclass_filter_netmask));
my $psaddrclass_filter_and1_filters;
ok($psaddrclass_filter_and1_filters = $psaddrclass_filter_and1->filters());
is(@{$psaddrclass_filter_and1_filters}, 2);
isa_ok($psaddrclass_filter_and1_filters->[0], 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::IPVersion');
isa_ok($psaddrclass_filter_and1_filters->[1], 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Netmask');
###Bring it together now in another And filter (should fully cover al types)
my $psaddrclass_filter_and2;
ok($psaddrclass_filter_and2 = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::And());
ok($psaddrclass_filter_and2->add_filter($psaddrclass_filter_not));
ok($psaddrclass_filter_and2->add_filter($psaddrclass_filter_or));
ok($psaddrclass_filter_and2->add_filter($psaddrclass_filter_and1));
my $psaddrclass_filter_and2_filters;
ok($psaddrclass_filter_and2_filters = $psaddrclass_filter_and2->filters());
is(@{$psaddrclass_filter_and2_filters}, 3);
isa_ok($psaddrclass_filter_and2_filters->[0], 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Not');
isa_ok($psaddrclass_filter_and2_filters->[1], 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Or');
isa_ok($psaddrclass_filter_and2_filters->[2], 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::And');
##AddressClass test that uses all of the above
##set the data source
my $psaddrclass;
ok($psaddrclass = new perfSONAR_PS::Client::PSConfig::AddressClasses::AddressClass());
is($psaddrclass->data_source(), undef);
is($psaddrclass->data_source($psaddrclass_ds_cc)->checksum(), $psaddrclass_ds_cc->checksum());
isa_ok($psaddrclass->data_source(), 'perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::CurrentConfig');
is($psaddrclass->data_source($psaddrclass_ds_ra)->checksum(), $psaddrclass_ds_ra->checksum());
isa_ok($psaddrclass->data_source(), 'perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::RequestingAgent');
##set the match filters
is($psaddrclass->match_filter(), undef);
is($psaddrclass->match_filter($psaddrclass_filter_and2)->checksum(), $psaddrclass_filter_and2->checksum());
isa_ok($psaddrclass->match_filter(), 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::And');
##set the exclude filters
is($psaddrclass->exclude_filter(), undef);
is($psaddrclass->exclude_filter($psaddrclass_filter_not)->checksum(), $psaddrclass_filter_not->checksum());
isa_ok($psaddrclass->exclude_filter(), 'perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Not');
##set archives
ok($psaddrclass->add_archive_ref('lbl-pt1.es.net'));
is($psaddrclass->add_archive_ref(), undef);
is($psaddrclass->archive_refs()->[0], 'lbl-pt1.es.net');
ok($psaddrclass->add_archive_ref('newy-pt1.es.net'));
is($psaddrclass->archive_refs()->[1], 'newy-pt1.es.net');
is($psaddrclass->archive_refs(['sacr-pt1.es.net'])->[0], 'sacr-pt1.es.net');
##add to config
is($psconfig->address_class("blah"), undef);#fail - map does not exist
is(keys %{$psconfig->address_classes()}, 0); 
is($psconfig->address_classes({"example", $psaddrclass})->{"example"}->checksum(), $psaddrclass->checksum());
is($psconfig->address_class("example", $psaddrclass)->checksum(), $psaddrclass->checksum());
is($psconfig->address_class(), undef); #fail - no key specified
is($psconfig->address_class("blah"), undef);#fail - key does not exist

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
is($psgrp_disjoint->excludes_self(), perfSONAR_PS::Client::PSConfig::Groups::ExcludeSelfScope::HOST);
is($psconfig->group("blah"), undef);#fail - map does not exist
is(keys %{$psconfig->groups()}, 0); 
is($psconfig->groups({"disjoint", $psgrp_disjoint})->{"disjoint"}->checksum(), $psgrp_disjoint->checksum());
is($psconfig->group("disjoint", $psgrp_disjoint)->checksum(), $psgrp_disjoint->checksum());
is($psconfig->group(), undef); #fail - no key specified
is($psconfig->group("blah"), undef);#fail - key does not exist
##Excludes
my $as_factory;
ok($as_factory = new perfSONAR_PS::Client::PSConfig::AddressSelectors::AddressSelectorFactory());
is($as_factory->build({}), undef);
is($as_factory->build(), undef);
is($as_factory->build({'name'=>''}), undef);
is($as_factory->build({'class'=>''}), undef);
my $excl_ap;
ok($excl_ap = new perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair());
my $excl_addr_sel_nl;
ok($excl_addr_sel_nl = new perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel());
is($excl_addr_sel_nl->name("lbl-pt1.es.net"), "lbl-pt1.es.net");
is($excl_addr_sel_nl->label("ipv6"), "ipv6");
is($excl_addr_sel_nl->disabled(1), 1);
is($excl_addr_sel_nl->disabled(0), 0);
my $excl_addr_sel_nl2;
ok($excl_addr_sel_nl2 = new perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel());
is($excl_addr_sel_nl2->name("sacr-pt1.es.net"), "sacr-pt1.es.net");
is($excl_ap->local_address($excl_addr_sel_nl)->checksum(), $excl_addr_sel_nl->checksum());
is($excl_ap->local_address()->checksum(), $excl_addr_sel_nl->checksum());
my $excl_addr_sel_class;
ok($excl_addr_sel_class = new perfSONAR_PS::Client::PSConfig::AddressSelectors::Class());
is($excl_addr_sel_class->class("example"), "example");
is($excl_ap->target_addresses([$excl_addr_sel_class])->[0]->checksum(), $excl_addr_sel_class->checksum());
ok($excl_ap->add_target_address($excl_addr_sel_nl2));
is($excl_ap->target_addresses()->[1]->checksum(), $excl_addr_sel_nl2->checksum());
ok($psgrp_disjoint->add_exclude($excl_ap));
is($psgrp_disjoint->add_exclude(), undef);#fail - no val
is($psgrp_disjoint->excludes()->[0]->checksum(), $excl_ap->checksum());
ok($psgrp_disjoint->add_exclude($excl_ap)); #test when already and exclude
is($psgrp_disjoint->excludes([$excl_ap])->[0]->checksum(), $excl_ap->checksum());
is($psgrp_disjoint->excludes("blah"), undef);
is($psgrp_disjoint->excludes(["blah"]), undef);

##Disjoint specific
is(@{$psgrp_disjoint->a_addresses()}, 0);
is(@{$psgrp_disjoint->b_addresses()}, 0);
is($psgrp_disjoint->a_addresses([$excl_addr_sel_nl2])->[0]->checksum(), $excl_addr_sel_nl2->checksum());
is($psgrp_disjoint->a_addresses(["blah"]), undef);
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
#Test group factory edge cases
########
my $grp_factory;
ok($grp_factory = new perfSONAR_PS::Client::PSConfig::Groups::GroupFactory());
is($grp_factory->build(), undef);
is($grp_factory->build({}), undef);
is($grp_factory->build({'type'=>'blah'}), undef);

########
# Test Archives
########
my $psarchive;
ok($psarchive = new perfSONAR_PS::Client::PSConfig::Archive());
is($psarchive->archiver('esmond'), 'esmond');
is($psarchive->ttl('PT1D'), undef); #fail -invalid
is($psarchive->ttl('P1D'), 'P1D');
is($psarchive->ttl(), 'P1D');
is($psarchive->archiver_data(), undef); # fail - no val
is($psarchive->archiver_data("blah"), undef); # fail - invalid val
is($psarchive->archiver_data({'_api_key' => 'ABC123'})->{'_api_key'}, 'ABC123');
is($psarchive->archiver_data_param('url', 'https://foo.bar/esmond/perfsonar/archive/'), 'https://foo.bar/esmond/perfsonar/archive/');
is($psarchive->archiver_data_param('_api_key'), 'ABC123');
is($psarchive->archiver_data_param(), undef); # fail - null key

##Test transform
my $psarchive_jq;
ok($psarchive_jq = new perfSONAR_PS::Client::PSConfig::JQTransform());
is($psarchive_jq->script('.'), '.');
is($psarchive_jq->output_raw(0), 0);
is($psarchive->transform($psarchive_jq)->checksum(), $psarchive_jq->checksum());
is($psarchive->transform()->checksum(), $psarchive_jq->checksum());

##Test connecting archives to config
is($psconfig->archive("blah"), undef);#fail - map does not exist
is(keys %{$psconfig->archives()}, 0); 
is($psconfig->archives({"lbl-pt1.es.net", $psarchive})->{"lbl-pt1.es.net"}->checksum(), $psarchive->checksum());
is($psconfig->archive("lbl-pt1.es.net", $psarchive)->checksum(), $psarchive->checksum());
is($psconfig->archive(), undef); #fail - no key specified
is($psconfig->archive("blah"), undef);#fail - key does not exist

########
# Test Schedules
########
my $psschedule;
ok($psschedule = new perfSONAR_PS::Client::PSConfig::Schedule());
is($psschedule->psconfig_meta({'foo'=> 'bar'})->{'foo'}, 'bar');
is($psschedule->psconfig_meta_param('project', 'perfSONAR'), 'perfSONAR');
## _field_timestampabsrel
is($psschedule->start('blah'), undef);
is($psschedule->start('PT1H'), 'PT1H');
is($psschedule->start('@PT1H'), '@PT1H');
####
is($psschedule->start('2017-10-23T17:56:52+00:00'), '2017-10-23T17:56:52+00:00');
is($psschedule->start(), '2017-10-23T17:56:52+00:00');
is($psschedule->slip('PT10M'), 'PT10M');
is($psschedule->sliprand(0), 0);
is($psschedule->sliprand(1), 1);
is($psschedule->repeat('PT60M'), 'PT60M');
is($psschedule->until('2017-10-24T17:56:52+00:00'), '2017-10-24T17:56:52+00:00');
is($psschedule->max_runs(0), undef);
is($psschedule->max_runs(24), 24);
is($psschedule->max_runs(), 24);
##Test connecting schedules to config
is($psconfig->schedule("blah"), undef);#fail - map does not exist
is(keys %{$psconfig->schedules()}, 0); 
is($psconfig->schedules({"example", $psschedule})->{"example"}->checksum(), $psschedule->checksum());
is($psconfig->schedule("example", $psschedule)->checksum(), $psschedule->checksum());
is($psconfig->schedule(), undef); #fail - no key specified
is($psconfig->schedule("blah"), undef);#fail - key does not exist

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
is($pstest->spec_param(), undef); #fail - no key
is($pstest->spec_param("blah"), undef); #fail - no val
##Test connecting tests to config
is($psconfig->test("blah"), undef);#fail - map does not exist
is(keys %{$psconfig->tests()}, 0); 
is($psconfig->tests({"example", $pstest})->{"example"}->checksum(), $pstest->checksum());
is($psconfig->test("example", $pstest)->checksum(), $pstest->checksum());
is($psconfig->test(), undef); #fail - no key specified
is($psconfig->test("blah"), undef);#fail - key does not exist

########
#Test Hosts
########
my $pshost;
ok($pshost = new perfSONAR_PS::Client::PSConfig::Host());
is($pshost->psconfig_meta({'foo'=> 'bar'})->{'foo'}, 'bar');
is($pshost->psconfig_meta_param('project', 'perfSONAR'), 'perfSONAR');
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
is($psconfig->host("blah"), undef);#fail - map does not exist
is(keys %{$psconfig->hosts()}, 0); 
is($psconfig->hosts({"lbl-pt1.es.net", $pshost})->{"lbl-pt1.es.net"}->checksum(), $pshost->checksum());
is($psconfig->host("lbl-pt1.es.net", $pshost)->checksum(), $pshost->checksum());
is($psconfig->host(), undef); #fail - no key specified
is($psconfig->host("blah"), undef);#fail - key does not exist

########
# Test Contexts
########
my $pscontext;
ok($pscontext = new perfSONAR_PS::Client::PSConfig::Context());
is($pscontext->context('linux-namespace'), 'linux-namespace');
is($pscontext->context_data({'foo' => 'bar'})->{'foo'}, 'bar');
is($pscontext->context_data_param('namespace', 'foobar'), 'foobar');
is($pscontext->context_data_param('namespace'), 'foobar');
is($pscontext->context_data_param(), undef); #fail - no key

##Test connecting contexts to config
is($psconfig->context("blah"), undef);#fail - map does not exist
is(keys %{$psconfig->contexts()}, 0); 
is($psconfig->contexts({"ctx1", $pscontext})->{"ctx1"}->checksum(), $pscontext->checksum());
is($psconfig->context("ctx1", $pscontext)->checksum(), $pscontext->checksum());
is($psconfig->context(), undef); #fail - no key specified
is($psconfig->context("blah"), undef);#fail - key does not exist

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
is($pstask->reference_param(), undef); #fail - no field
##Test connecting tasks to config
is($psconfig->task("blah"), undef);#fail - map does not exist
is(keys %{$psconfig->tasks()}, 0); 
is($psconfig->tasks({"task1", $pstask})->{"task1"}->checksum(), $pstask->checksum());
is($psconfig->task("task1", $pstask)->checksum(), $pstask->checksum());
is($psconfig->task(), undef); #fail - no key specified
is($psconfig->task("blah"), undef);#fail - key does not exist

########
#Test subtasks
########
my $pssubtask;
ok($pssubtask = new perfSONAR_PS::Client::PSConfig::Subtask());
is($pssubtask->psconfig_meta({'foo'=> 'bar'})->{'foo'}, 'bar');
is($pssubtask->psconfig_meta_param('project', 'perfSONAR'), 'perfSONAR');
is($pssubtask->test_ref("example"), "example");
is($pssubtask->schedule_offset(), undef);
my $psschedule_offset;
ok($psschedule_offset = new perfSONAR_PS::Client::PSConfig::ScheduleOffset());
is($psschedule_offset->type('start'), 'start');
##edge cases of _field_enum
is($psschedule_offset->relation('blah'), undef);
is($psschedule_offset->relation(), undef);
is($psschedule_offset->_field_enum('relation', 'blah'), 'blah');
##
is($psschedule_offset->relation('before'), 'before');


is($psschedule_offset->offset('PT5S'), 'PT5S');
is($pssubtask->schedule_offset($psschedule_offset)->checksum(), $psschedule_offset->checksum());
isa_ok($pssubtask->schedule_offset(), 'perfSONAR_PS::Client::PSConfig::ScheduleOffset');
ok($pssubtask->add_tool('iperf3'));
is($pssubtask->tools()->[0], 'iperf3');
ok($pssubtask->add_archive_ref('lbl-pt1.es.net'));
is($pssubtask->archive_refs()->[0], 'lbl-pt1.es.net');
is($pssubtask->disabled(1), 1);
is($pssubtask->disabled(0), 0);
is($pssubtask->reference({'foo' => 'bar'})->{'foo'}, 'bar');
is($pssubtask->reference_param('stuff', 'foobar'), 'foobar');
is($pssubtask->reference_param('stuff'), 'foobar');
is($pssubtask->reference_param(), undef); #fail - no field
##Test connecting tasks to config
is($psconfig->subtask("blah"), undef);#fail - map does not exist
is(keys %{$psconfig->subtasks()}, 0); 
is($psconfig->subtasks({"subtask1", $pssubtask})->{"subtask1"}->checksum(), $pssubtask->checksum());
is($psconfig->subtask("subtask1", $pssubtask)->checksum(), $pssubtask->checksum());
is($psconfig->subtask(), undef); #fail - no key specified
is($psconfig->subtask("blah"), undef);#fail - key does not exist

########
#Test includes
########
ok($psconfig->add_include('file:///tmp/tmp.tmp'));
is($psconfig->includes()->[0], 'file:///tmp/tmp.tmp');

########
#Test validation
########
is($psconfig->validate(), 0); #no validation errors


########
#Test additional utilities and edge cases - clears out JSON
########

is($excl_ap->_validate_duration(), 0); # fail -edge case for validate_duration
is(@{$excl_ap->target_addresses()}, 2);
is($excl_ap->remove_list_item('target_addresses'), undef); #fail - no index
is($excl_ap->remove_list_item('target_addresses', 'blah'), undef); #fail - bad index
is($excl_ap->remove_list_item('target_addresses', 2), undef); #fail - out of range
is($excl_ap->remove_list_item('blah', 0), undef); #fail - not a key
is($excl_ap->remove_list_item('local_address', 0), undef); #fail - not a list
$excl_ap->remove_list_item('target_addresses', 0);
is(@{$excl_ap->target_addresses()}, 1);
is(@{$excl_ap->target_addresses()}, 1);
#######
# _field_class() failure cases  
#######
is($excl_ap->_field_class(), undef);
is($excl_ap->_field_class("blah"), undef);
is($excl_ap->_field_class("foo", 'perfSONAR_PS::Client::PSConfig::Config', "bar"), undef);
#######
# _field_class_map_item() failure cases  
#######
is($excl_ap->_field_class_map_item(), undef);
is($excl_ap->_field_class_map_item("blah"), undef);
is($excl_ap->_field_class_map_item("foo", 'perfSONAR_PS::Client::PSConfig::Config'), undef);
is($excl_ap->_field_class_map_item("foo", 'perfSONAR_PS::Client::PSConfig::Config', "bar"), undef);
is($excl_ap->_field_class_map_item("foo", 'perfSONAR_PS::Client::PSConfig::Config', "bar", "foobar"), undef);
#######
# _field_class_factory() failure cases  
#######
is($excl_ap->_field_class_factory(), undef);
is($excl_ap->_field_class_factory("blah"), undef);
is($excl_ap->_field_class_factory("foo", 
    'perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::DataSourceFactory',
    'perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::BaseDataSource',
    'bar'
    ), undef);
#######
# _field_anyobj_param() failure cases  
#######
is($excl_ap->_field_anyobj_param(), undef);
#######
# _add_field_class() failure cases  
#######
is($excl_ap->_add_field_class(), undef);
is($excl_ap->_add_field_class("foo"), undef);
is($excl_ap->_add_field_class("foo", 
    'perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::BaseDataSource',
    'bar'
    ), undef);
#######
# _validate_class() failure cases  
#######
is($excl_ap->_validate_class("blah"), 0);
is($excl_ap->_validate_name(), 0);
    
is(@{$psaddr->label_names()}, 1);
ok($psaddr->remove_label("ipv6"));
is($psaddr->remove_label("blah"), undef);#fail - no label
is($psaddr->_remove_map_item("blah", "blah"), undef);#fail - no map
is(@{$psaddr->label_names()}, 0);
ok($psaddr->remove('labels'));
is($psaddr->label("ipv6"), undef); #fail - labels undef
ok(!exists $psaddr->data()->{'labels'});
is($psaddr->remove('labels'), undef); #fail - no map
is(@{$psaddr->label_names()}, 0); #fail - no labels
$psaddr->data()->{'foo'} = {'bar' => undef }; #setup for fail - exists but undef
ok(! $psaddr->_has_field($psaddr->data()->{'foo'}, 'bar'));#fail - exists but undef

is(@{$psaddr->remote_address_names()}, 1);
ok($psaddr->remove_remote_address("10.0.0.2"));
is(@{$psaddr->remote_address_names()}, 0);
ok($psaddr->remove('remote_addresses'));
ok(!exists $psaddr->data()->{'remote_addresses'});

is(@{$psconfig->address_names()}, 1);
ok($psconfig->remove_address("lbl-pt1.es.net"));
is(@{$psconfig->address_names()}, 0);
ok($psconfig->remove('addresses'));
ok(!exists $psconfig->data()->{'addresses'});

is(@{$psconfig->address_class_names()}, 1);
ok($psconfig->remove_address_class("example"));
is(@{$psconfig->address_class_names()}, 0);
ok($psconfig->remove('address_classes'));
ok(!exists $psconfig->data()->{'address_classes'});

is(@{$psconfig->archive_names()}, 1);
ok($psconfig->remove_archive("lbl-pt1.es.net"));
is(@{$psconfig->archive_names()}, 0);
ok($psconfig->remove('archives'));
ok(!exists $psconfig->data()->{'archives'});

is(@{$psconfig->context_names()}, 1);
ok($psconfig->remove_context("ctx1"));
is(@{$psconfig->context_names()}, 0);
ok($psconfig->remove('contexts'));
ok(!exists $psconfig->data()->{'contexts'});

is(@{$psconfig->group_names()}, 3);
ok($psconfig->remove_group("disjoint"));
is(@{$psconfig->group_names()}, 2);
ok($psconfig->remove('groups'));
ok(!exists $psconfig->data()->{'groups'});

is(@{$psconfig->host_names()}, 1);
ok($psconfig->remove_host("lbl-pt1.es.net"));
is(@{$psconfig->host_names()}, 0);
ok($psconfig->remove('hosts'));
ok(!exists $psconfig->data()->{'hosts'});

is(@{$psconfig->schedule_names()}, 1);
ok($psconfig->remove_schedule("example"));
is(@{$psconfig->schedule_names()}, 0);
ok($psconfig->remove('schedules'));
ok(!exists $psconfig->data()->{'schedules'});

is(@{$psconfig->task_names()}, 1);
ok($psconfig->remove_task("task1"));
is(@{$psconfig->task_names()}, 0);
ok($psconfig->remove('tasks'));;
ok(!exists $psconfig->data()->{'tasks'});

is(@{$psconfig->subtask_names()}, 1);
ok($psconfig->remove_subtask("subtask1"));
is(@{$psconfig->subtask_names()}, 0);
ok($psconfig->remove('subtasks'));;
ok(!exists $psconfig->data()->{'subtasks'});

is(@{$psconfig->test_names()}, 1);
ok($psconfig->remove_test("example"));
is(@{$psconfig->test_names()}, 0);
ok($psconfig->remove('tests'));
ok(!exists $psconfig->data()->{'tests'});

ok($psconfig->remove('includes'));

ok($psconfig->remove_psconfig_meta());
ok(!exists $psconfig->data()->{'_meta'});
is($psconfig->psconfig_meta_param('project'), undef); #fail - null _meta

is($psconfig->validate(), 4); #should have 1 error for each missing required field
is($psconfig->json(), '{}');
is($psconfig->json({ 'utf8' => undef, 'canonical' => undef}), '{}');
is($psconfig->json({ 'utf8' => 0, 'canonical' => 0}), '{}');

##################################################################
#TODO: Delete below
diag($psconfig->json({'pretty' => 1}));
##################################################################

########
#finish testing
########
done_testing();
