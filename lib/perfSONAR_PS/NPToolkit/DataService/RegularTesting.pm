package perfSONAR_PS::NPToolkit::DataService::RegularTesting;

use strict;
use warnings;

use Params::Validate qw(:all);
use Data::Dumper;
use JSON;

use base 'perfSONAR_PS::NPToolkit::DataService::BaseConfig';

use fields qw( psconfig_writer );

# BEGIN use statements copied from old regular testing

use CGI qw/:standard/;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Ajax;
use CGI::Session;
use Template;
use Template::Filters;
use Config::General;
use Log::Log4perl qw(get_logger :easy :levels);
use Net::IP;
use Params::Validate;
use Storable qw(store retrieve freeze thaw dclone);

use perfSONAR_PS::Utils::DNS qw( reverse_dns resolve_address reverse_dns_multi resolve_address_multi );
use perfSONAR_PS::Utils::Host qw( get_ethernet_interfaces get_interface_addresses discover_primary_address );
use perfSONAR_PS::Client::gLS::Keywords;
use perfSONAR_PS::NPToolkit::Config::RegularTesting;
use perfSONAR_PS::NPToolkit::Config::PSConfigWriter;
use perfSONAR_PS::Common qw(find findvalue extract genuid);
use perfSONAR_PS::Web::Sidebar qw(set_sidebar_vars);

use Data::Validate::IP qw(is_ipv4);
use Data::Validate::Domain qw(is_hostname);
use Net::IP;
use Time::HiRes qw( time );

use JSON qw(from_json);

sub new {

    my ( $class, @params ) = @_;
    my $parameters = validate( @params, { test_config_defaults_file => 0,
            load_regular_testing => 0,
            load_ls_registration => 0,
            config_file => 0,
        } );

    my $self = fields::new( $class );

    $self->{LOGGER} = get_logger( $class );

    my $config_file = $parameters->{'config_file'};
    my $test_params = {};
    $test_params->{'regular_testing_config_file'} = $config_file if $config_file;

    my $regular_testing_conf = perfSONAR_PS::NPToolkit::Config::RegularTesting->new( );
    $regular_testing_conf->init( $test_params );
    $self->{test_config_defaults_file} = $parameters->{test_config_defaults_file};
    $self->{regular_testing_conf} = $regular_testing_conf;

    my $params = ();
    my $psconfig_file = '/etc/perfsonar/psconfig/pscheduler.d/toolkit-webui.json';
    $params->{psconfig_config_file} = $psconfig_file;
    my $psconfig_writer = perfSONAR_PS::NPToolkit::Config::PSConfigWriter->new( $params );
    $psconfig_writer->init;
    $self->{psconfig_writer} = $psconfig_writer;

    return $self;

}

sub add_test_configuration {

    my $self = shift;
    my $caller = shift;
    my $input_data = $caller->{'input_params'}->{'POSTDATA'};
    my $json_text = $input_data->{'value'};

    utf8::encode($json_text) if utf8::is_utf8($json_text);
    my $data = from_json($json_text, {utf8 => 1});

    my $response = $self->_add_test_configuration($data);
    return $response;

}

sub delete_all_tests{
    my $self = shift;
    #my $regular_testing_conf = $self->{regular_testing_conf};
    #my ($ret_val, $ret_message) = $regular_testing_conf->delete_all_tests();
    my $psconfig_writer = $self->{psconfig_writer};
    my ($ret_val, $ret_message) = $psconfig_writer->delete_all_psconfig_tests();

    my $result = ();
    $result->{"Error message"} = $ret_message;
    $result->{"Return code"} = $ret_val;

    return $result;


}

#deletes all the tests and adds the configuration
sub update_test_configuration{

    my $self = shift;
    my $caller = shift;
    my $input_data = $caller->{'input_params'}->{'POSTDATA'};
    my $json_text = $input_data->{'value'};

    utf8::encode($json_text) if utf8::is_utf8($json_text);
    my $data = from_json($json_text, {utf8 => 1});

    #print("JOVANA: " . $data);

    my $response = $self->delete_all_tests();
#return $response;

    if($response->{"Return code"} == 0 and $input_data){
        my $update_response = $self->_add_test_configuration($data);
        return $update_response;
    }

    return $response->{"Error message"};
    return $response;


}



sub get_test_configuration {
    my $self = shift;
    my $testing_conf = $self->{regular_testing_conf};

    if (!($self->{regular_testing_conf})) {
        return {error => "Regular testing config must be loaded before getting test configuration"};
    }

    my $tests = [];
    my ( $status, $res ) = $testing_conf->get_tests();
    if ( $status == 0 ) {
        $tests = $res;
    } else {
        $tests = [];
    }

    my @sorted_tests = sort { $a->{description} cmp $b->{description} } @$tests;
    $tests = \@sorted_tests;

    foreach my $test (@$tests) {
        my $test_id = $test->{id};
        $test_id =~ s/test\.//g;
        $test->{test_id} = $test_id;

        my $current_test = $test_id;

        foreach my $member (@{ $test->{members} }) {
            my $member_id = $member->{id};
            $member_id =~ s/member\.//g;
            $member->{member_id} = $member_id;
        }

    }

    my $status_vars = $self->get_status($tests);

    my $test_defaults = $self->get_default_test_parameters();

    return {
        test_configuration => $tests,
        status => $status_vars,
        test_defaults => $test_defaults,
    };
}

sub get_status {
    my ( $self, $tests ) = @_;
    my $testing_conf = $self->{regular_testing_conf};

    # Calculates whether or not they have a "good" configuration

    my ($status, $res);
    my $status_vars = {};

    my $hosts_file_matches_dns;

    my $psb_throughput_tests = 0;
    my $pinger_tests         = 0;
    my $psb_owamp_tests      = 0;
    my $network_usage        = 0;
    my $owamp_port_usage     = 0;
    my $traceroute_tests     = 0;

        foreach my $test ( @{$tests} ) {
            if ( $test->{type} eq "bwctl/throughput" ) {
                $psb_throughput_tests++;
            }
            elsif ( $test->{type} eq "pinger" ) {
                $pinger_tests++;
            }
            elsif ( $test->{type} eq "owamp" ) {
                $psb_owamp_tests++;
            }
            elsif ( $test->{type} eq "traceroute" ) {
                $traceroute_tests++;
            }

            if ( $test->{type} eq "owamp" ) {
                foreach my $member ( @{ $test->{members} } ) {
                    if ( $member->{sender} ) {
                        $owamp_port_usage += 2;
                    }
                    if ( $member->{receiver} ) {
                        $owamp_port_usage += 2;
                    }
                }
            }

            if ( $test->{type} eq "bwctl/throughput" ) {
                my $test_duration = $test->{parameters}->{duration};
                my $test_interval = $test->{parameters}->{test_interval};

                my $num_tests = 0;
                foreach my $member ( @{ $test->{members} } ) {
                    if ( $member->{sender} ) {
                        $num_tests++;
                    }
                    if ( $member->{receiver} ) {
                        $num_tests++;
                    }
                }

                # Add 15 seconds onto the duration to account for synchronization issues
                $test_duration += 15;

                $network_usage += ( $num_tests * $test_duration ) / $test_interval if ($test_interval > 0);
            }
        }

    my %owamp_ports = ();
    my $owamp_port_range;

    ($status, $res) = $testing_conf->get_local_port_range({ test_type => "owamp" });
    if ($status == 0) {
        if ($res) {
            $owamp_ports{min_port} = $res->{min_port};
            $owamp_ports{max_port} = $res->{max_port};
        }
    }

    if (defined $owamp_ports{min_port} and defined $owamp_ports{max_port}) {
        $owamp_port_range = $owamp_ports{max_port} - $owamp_ports{min_port} + 1;
    }

    $status_vars->{network_percent_used}    = sprintf "%.1d", $network_usage * 100;
    $status_vars->{hosts_file_matches_dns} = $hosts_file_matches_dns;
    $status_vars->{owamp_ports}             = \%owamp_ports;
    $status_vars->{owamp_port_range}        = $owamp_port_range;
    $status_vars->{owamp_port_usage}        = $owamp_port_usage;
    $status_vars->{owamp_tests}             = $psb_owamp_tests;
    $status_vars->{pinger_tests}            = $pinger_tests;
    $status_vars->{throughput_tests}        = $psb_throughput_tests;
    $status_vars->{traceroute_tests}        = $traceroute_tests;

    return $status_vars;
}


sub _add_test_configuration{

    my $self = shift;
    my $data = shift;

    my @result=[];
    my $ret_val=-1;

    #my $regular_testing_conf = $self->{regular_testing_conf};

    if($data){

        my $tests = $data->{'data'};

        if($tests){

            foreach my $test (@{$tests}){

                my $test_type =  $test->{'type'};
                my $disabled = $test->{'disabled'};
                my $description = $test->{'description'};
		#my @members = $test->{'members'};
		#my $members = $test->{'members'};
                my $parameters =  $test->{'parameters'};
                my $added_by_mesh = $test->{'added_by_mesh'};
                $parameters->{'description'} = $description;
                $parameters->{'disabled'} = $disabled;
                $parameters->{'added_by_mesh'} = $added_by_mesh;
		#$parameters->{'members'} = \@members;
		$parameters->{'members'} = $test->{'members'}; #$members;

#my $response1 = ();
#        $response1->{"Return code"}= -1;
#	#$response1->{"Error message"}= "JOVANA " . Dumper(@members);
#	#$response1->{"Error message"}= "JOVANA " . Dumper($members);
#	$response1->{"Error message"}= "". Dumper($parameters);
#        $response1->{"tests_added"} = \@result;
#return $response1;
                my $test_id;
                if($test_type eq 'latencybg'){

#		    print($parameters);
		    #$test_id = $regular_testing_conf->add_test_owamp($parameters);
                    $test_id = $self->{psconfig_writer}->add_test_owamp($parameters) ;

#my $response1 = ();
#        $response1->{"Return code"}= -1;
#	#$response1->{"Error message"}= "JOVANA " . Dumper(@members);
#	#$response1->{"Error message"}= "JOVANA " . Dumper($members);
#	$response1->{"Error message"}= "Latency-bg ". Dumper($parameters);
#        $response1->{"tests_added"} = \@result;
#return $response1;
                }elsif($test_type eq 'throughput'){

                    #$test_id = $regular_testing_conf->add_test_bwctl_throughput($parameters);
		    $test_id = $self->{psconfig_writer}->add_test_bwctl_throughput($parameters);

                }elsif($test_type eq 'rtt'){

	            #$test_id = $regular_testing_conf->add_test_pinger($parameters);
		    $test_id = $self->{psconfig_writer}->add_test_pinger($parameters);
#my $response1 = ();
#        $response1->{"Return code"}= -1;
#	#$response1->{"Error message"}= "JOVANA " . Dumper(@members);
#	#$response1->{"Error message"}= "JOVANA " . Dumper($members);
#	$response1->{"Error message"}= "Pre save ". Dumper($test_id);
#        $response1->{"tests_added"} = \@result;
#return $response1;

                }elsif($test_type eq 'trace'){

		    #$test_id = $regular_testing_conf->add_test_traceroute($parameters);
		    $test_id = $self->{psconfig_writer}->add_test_traceroute($parameters);;

                }

		#if($test_id){
		#    foreach my $member (@{$members}){
		#        $member->{'test_id'} = $test_id;
		#        my $ret = $self->{psconfig_writer}->add_test_member($member);
		#
		#    }
		#    push @result, $test;
		#}

            } #foreach test
#my $response1 = ();
#        $response1->{"Return code"}= -1;
#	#$response1->{"Error message"}= "JOVANA " . Dumper(@members);
#	#$response1->{"Error message"}= "JOVANA " . Dumper($members);
#	$response1->{"Error message"}= "Pre default ". Dumper($data);
#        $response1->{"tests_added"} = \@result;
#return $response1;
    my ($status, $res) = $self->{psconfig_writer}->add_default_trace_tests();
#my $response1 = ();
#        $response1->{"Return code"}= -1;
#	#$response1->{"Error message"}= "JOVANA " . Dumper(@members);
#	#$response1->{"Error message"}= "JOVANA " . Dumper($members);
#	$response1->{"Error message"}= "Posle default ". Dumper($data);
#	$response1->{"Error message"}= $res;
#        $response1->{"tests_added"} = \@result;
#return $response1;
        } # if tests
    } # if data
    #
    my $response = ();
    if(@result){
	#my ($ret_val, $ret_message) = $regular_testing_conf->save( { restart_services => 0 } );
        my ($ret_val, $ret_message) = $self->{psconfig_writer}->save_psconfig_tasks( \@result );
        $response->{"tests_added"} = \@result;
        $response->{"Return code"}= $ret_val;
        $response->{"Error message"}= $ret_message;

    }else{
        $response->{"Return code"}= -1;
        $response->{"Error message"}= "Error adding tests";
        $response->{"tests_added"} = \@result;
    }

    return $response;

}

sub get_default_test_parameters {
    my $self = shift;
    my $config_file = $self->{test_config_defaults_file}; # $basedir . '/etc/test_config_defaults.conf';
    my $conf_obj = Config::General->new( -ConfigFile => $config_file );
    my %conf = $conf_obj->getall;
    return \%conf;
}


1;

# vim: expandtab shiftwidth=4 tabstop=4
