#!/usr/bin/perl
package perfSONAR_PS::NPToolkit::Config::PSConfigParserTest;
#BaseAgent.pm (perfSONAR_PS/PSConfig/ )

use Mouse;

use CHI;
use Data::Dumper;
use Data::Validate::Domain qw(is_hostname);
use Data::Validate::IP qw(is_ipv4 is_ipv6 is_loopback_ipv4);
use Net::CIDR qw(cidrlookup);
use File::Basename;
use JSON qw/ from_json /;
use Log::Log4perl qw(get_logger);
use URI;
use Params::Validate qw(:all);


use perfSONAR_PS::NPToolkit::Config::PSConfigParser;
#use perfSONAR_PS::NPToolkit::Config::PSConfigParserTest;
use perfSONAR_PS::Client::PSConfig::ApiConnect;
use perfSONAR_PS::Client::PSConfig::ApiFilters;
use perfSONAR_PS::Client::PSConfig::Archive;
use perfSONAR_PS::Client::PSConfig::Parsers::TaskGenerator;
#use perfSONAR_PS::PSConfig::ArchiveConnect;
#use perfSONAR_PS::Utils::Logging;
#use perfSONAR_PS::PSConfig::RequestingAgentConnect;
#use perfSONAR_PS::PSConfig::TransformConnect;
#use perfSONAR_PS::Utils::DNS qw(resolve_address reverse_dns);
#use perfSONAR_PS::Utils::Host qw(get_ips);
#use perfSONAR_PS::Utils::ISO8601 qw/duration_to_seconds/;
use perfSONAR_PS::RegularTesting::Utils::ConfigFile qw( parse_file );
use perfSONAR_PS::RegularTesting::Config qw( parse );

our $VERSION = 4.1;

__PACKAGE__->run( @ARGV ) unless caller();

sub run { 
	print "I'm a test script!\n" ;

	my $file_name = "/var/lib/perfsonar/toolkit/gui-tasks.conf";
	my @params = { file => $file_name };

        my $parameters = validate( @params, { file => 1, } );
	#print("parameters ".Dumper($parameters)."\n");
        my $file = $parameters->{file};
	#print("\tfile ".Dumper($file));





	#my %initialConfigFile = parse_file( file => $file );
	#print("parsed old test configuration ".Dumper(%initialConfigFile)."\n");

#        my ($status, $res) = parse_file( file => $file ); 
#	print("parsed old test configuration ".Dumper($res)."\n");



#	my $config = perfSONAR_PS::RegularTesting::Config->parse($res);
#	print("parsed again ref $config\n".Dumper($config)."\n");
 
	#my $ja = perfSONAR_PS::NPToolkit::Config::PSConfigParser->new();
	my $ja = new perfSONAR_PS::NPToolkit::Config::PSConfigParser;
	$ja->init;
	#my @tasks = $ja->_run_handle_psconfig();
	my $tests = $ja->map_psconfig_tasks_to_toolkit_UI();
	#my $uiTests = $ja->get_test_configuration();
	print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");    
	print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");    
	print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");    
	#print("Tasks: ". Dumper(@tasks)."\n");    
	print("Tests: ". Dumper($tests)."\n");
	#print("UI tests: ". Dumper($uiTests)."\n");    

}

1;
