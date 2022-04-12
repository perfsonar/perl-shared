package perfSONAR_PS::NPToolkit::DataService::Host;

use strict;
use warnings;


use POSIX;

use Sys::Hostname;

use perfSONAR_PS::Utils::Host qw(get_ntp_info get_operating_system_info get_processor_info get_tcp_configuration get_ethernet_interfaces discover_primary_address get_health_info is_auto_updates_on get_interface_addresses get_interface_addresses_by_type get_interface_speed get_interface_mtu get_interface_counters get_interface_hostnames get_interface_mac get_dmi_info);

use perfSONAR_PS::Utils::LookupService qw( is_host_registered get_client_uuid );
use perfSONAR_PS::NPToolkit::Config::LSRegistrationDaemon;
use perfSONAR_PS::Client::gLS::Keywords;
use perfSONAR_PS::NPToolkit::Services::ServicesMap qw(get_service_object);

use perfSONAR_PS::NPToolkit::Config::OWAMP;
use perfSONAR_PS::NPToolkit::Config::TWAMP;
use perfSONAR_PS::NPToolkit::DataService::Communities;
use perfSONAR_PS::Utils::GeoLookup qw(geoIPLookup);
use perfSONAR_PS::PSConfig::PScheduler::ConfigConnect;

use Data::Dumper;


use Time::HiRes qw(gettimeofday tv_interval);

use base qw(perfSONAR_PS::NPToolkit::DataService::BaseConfig);

use perfSONAR_PS::NPToolkit::ConfigManager::Utils qw( save_file start_service restart_service stop_service );


sub get_admin_information {
    my $self = shift;
    my $ls_conf = $self->{ls_conf};
    if (keys %$ls_conf < 1) {
        return {
		administrator => {
        }, 
        location => {
        }
	};
    }

    my $info = {
        administrator => {
            name => $ls_conf->get_administrator_name(),
            email => $ls_conf->get_administrator_email(),
            organization => $ls_conf->get_organization_name()
        },
        location => {
            city => $ls_conf->get_city(),
            state => $ls_conf->get_state(),
            country => $ls_conf->get_country(),
            zipcode => $ls_conf->get_zipcode(),
            latitude => $ls_conf->get_latitude(),
            longitude => $ls_conf->get_longitude(),
        },
    };

    return $info;

}

sub get_metadata {
    my $self = shift;
    my $meta = {};
    my $ls_conf = $self->{ls_conf};
    if (!defined $ls_conf) {
        return { 'error' => 'LS Registration Daemon config object not found' };
    }

    my $config = {};
    my $config_full = {};
if ( defined $ls_conf->{'CONFIG_FILE'} ) {
    $config_full = $ls_conf->load_config( { file => $ls_conf->{'CONFIG_FILE'} } );
} 
    $config->{'role'} = $config_full->{'role'};
    $config->{'access_policy'} = $config_full->{'access_policy'};
    $config->{'access_policy_notes'} = $config_full->{'access_policy_notes'};

    $config->{'site_name'} = $config_full->{'site_name'};
    $config->{'organization'} = $config_full->{'organization'};
    $config->{'domain'} = $config_full->{'domain'};

    $meta->{'config'} = $config;


    my $info = $self->get_admin_information();
    $meta = { %$meta, %$info };

    my $communities = $config_full->{site_project};
    if ( defined $communities ) {
        my $comm = { 'communities' => $communities };
        $meta = { %$meta, %$comm };
    }

    return $meta;

}

sub update_metadata {
    my $self = shift;
    my $caller = shift;
    my $args = $caller->{'input_params'};
    my $ls_conf = $self->{ls_conf};

    my %config_args = ();
    my @field_names = (
        'role',
        'access_policy',
        'access_policy_notes',
        'site_name',
        'domain',
        'communities',
        'organization_name',
        'admin_name',
        'admin_email',
        'city',
        'country',
        'state',
        'postal_code',
        'latitude',
        'longitude',
    );

    foreach my $field (@field_names) {
        if ( defined ( $args->{$field} ) && $args->{$field}->{is_set} == 1) {
            $config_args{$field} = $args->{$field}->{value};
        }
    }

    my $role = $config_args{'role'};
    my $access_policy = $config_args{'access_policy'};
    my $access_policy_notes = $config_args{'access_policy_notes'};
    
    my $site_name = $config_args{'site_name'};
    my $domain = $config_args{'domain'};
    
    my $communities = $config_args{'communities'};

    my $organization_name = $config_args{organization_name}; #  if (exists $args{organization_name});
    my $administrator_name = $config_args{admin_name}; # if (exists $args{administrator_name});
    my $administrator_email = $config_args{admin_email}; # if (exists $args{administrator_email});
    my $city = $config_args{city};
    my $state = $config_args{state};
    my $zipcode = $config_args{postal_code};
    my $country = $config_args{country};
    my $latitude = $config_args{latitude};
    my $longitude = $config_args{longitude};
    my $subscribe = $config_args{subscribe};

    $ls_conf->set_organization_name( { organization_name => $organization_name } ) if defined $organization_name;
    $ls_conf->set_administrator_name( { administrator_name => $administrator_name } ) if defined $administrator_name;
    $ls_conf->set_administrator_email( { administrator_email => $administrator_email } ) if defined $administrator_email;
    $ls_conf->set_city( { city => $city } ) if defined $city;
    $ls_conf->set_state( { state => $state } ) if defined $state;
    $ls_conf->set_country( { country => $country } ) if defined $country;
    $ls_conf->set_zipcode( { zipcode => $zipcode } ) if defined $zipcode;
    $ls_conf->set_latitude( { latitude => $latitude } ) if defined $latitude;
    $ls_conf->set_longitude( { longitude => $longitude } ) if defined $longitude;

    if($administrator_email && defined ($subscribe) && $subscribe == 1){
        subscribe($administrator_email);
    }

    $ls_conf->set_role( { role => $role } ) if defined $role && @$role >= 0;
    $ls_conf->set_access_policy( { access_policy => $access_policy } ) if defined $access_policy;
    $ls_conf->set_access_policy_notes( { access_policy_notes => $access_policy_notes } ) if defined $access_policy_notes;
    
    $ls_conf->set_site_name( { site_name => $site_name } ) if defined $site_name;
    $ls_conf->set_domain( { domain => $domain } ) if defined $domain;

    $ls_conf->set_projects( { projects => $communities } ) if defined $communities;
    

    return $self->save_ls_config();
}

sub get_calculated_lat_lon {
    my $self = shift;
    my $caller = shift;

    my $external_addresses = discover_primary_address({ disable_ipv4_reverse_lookup => 1, disable_ipv6_reverse_lookup => 1 });
    my $res = geoIPLookup($external_addresses->{primary_address});
    my $result = {};

    if($res->{longitude} && $res->{latitude} ){
        $result->{longitude} = $res->{longitude};
        $result->{latitude} = $res->{latitude};
    } 
    return $result;

}

sub get_details {
    my $self = shift;
    # get addresses, mtu, counters, ntp status, globally registered, toolkit version, toolkit rpm version
    # external address, total RAM, interface details, etc

    my $caller = shift;
    my %conf = %{$self->{config}};

    $self->{authenticated} = $caller->{authenticated};

    my $status = {};

    my $version_conf = perfSONAR_PS::NPToolkit::Config::Version->new();
    $version_conf->init();

    ## this function now gets all interfaces, not just ethernet
    my @interfaces = get_ethernet_interfaces();

    my @interfaceDetails;
    foreach my $interface (@interfaces){
        my $iface;
        my $addresses = get_interface_addresses_by_type({interface=>$interface});
        $iface = $addresses;    # sets $iface->{ipv4_address} and $iface->{ipv6_address}
        # function get_interface_hostnames() returns a hash (hash-ref) with keys=ip's, values = arrays of hostnames
        my $ipv4_addresses = $addresses->{ipv4_address};  # array-ref
        my $ipv4_hostnames = get_interface_hostnames({interface_addresses=>$ipv4_addresses}); 
        my $ipv6_addresses = $addresses->{ipv6_address};
        my $ipv6_hostnames = get_interface_hostnames({interface_addresses=>$ipv6_addresses}); 
        $iface->{hostnames} = {%$ipv4_hostnames, %$ipv6_hostnames};
        $iface->{mtu} = get_interface_mtu({interface_name=>$interface});
        $iface->{counters} = get_interface_counters({interface_name=>$interface});
        $iface->{speed} = get_interface_speed({interface_name=>$interface});
        $iface->{mac} = get_interface_mac({interface_name=>$interface});
        $iface->{iface} = $interface;

        push @interfaceDetails, $iface;
    }

    $status->{interfaces} = \@interfaceDetails;


    # Getting the external addresses seems to be by far the slowest thing here (~0.9 sec)

    my $external_addresses = discover_primary_address({
            interface => $conf{primary_interface},
            allow_rfc1918 => $conf{allow_internal_addresses},
            disable_ipv4_reverse_lookup => $conf{disable_ipv4_reverse_lookup},
            disable_ipv6_reverse_lookup => $conf{disable_ipv6_reverse_lookup},
        });


    my $external_address;
    my $external_address_iface;
    my $external_address_mtu;
    my $external_address_counters;
    my $external_address_speed;
    my $external_address_ipv4;
    my $external_address_ipv6;
    my $external_dns_name = "";
    my $is_registered = 0;

    if ($external_addresses) {
        $external_address = $external_addresses->{primary_address};
        $external_address_iface = $external_addresses->{primary_address_iface};
        $external_address_mtu = $external_addresses->{primary_iface_mtu};
        $external_address_counters = $external_addresses->{primary_iface_counters};
        $external_address_speed = $external_addresses->{primary_iface_speed} if $external_addresses->{primary_iface_speed};
        $external_address_ipv4 = $external_addresses->{primary_ipv4};
        $external_address_ipv6 = $external_addresses->{primary_ipv6};
        $external_dns_name = $external_addresses->{primary_dns_name}; 

        if ( !$external_address && !$external_address_ipv4 && !$external_address_ipv6) {
            $status->{all_addrs_private} = 1;
        } else {
            $status->{all_addrs_private} = 0;
        }
        $status->{external_address} = {
            address => $external_address,
            ipv4_address => $external_address_ipv4,
            ipv6_address => $external_address_ipv6,
        };
        $status->{external_address}->{dns_name} = $external_dns_name;
        $status->{external_address}->{iface} = $external_address_iface if $external_address_iface;
        $status->{external_address}->{speed} = $external_address_speed if $external_address_speed;
        $status->{external_address}->{mtu} = $external_address_mtu if $external_address_mtu;
        $status->{external_address}->{counters} = $external_address_counters if $external_address_counters;

    }

    $status->{configuration} = {} if not exists $status->{configuration}; #" in %$status);

    $status->{toolkit_name}=$conf{toolkit_name};
    $status->{privacy_link}=$conf{privacy_link};
    $status->{privacy_text}=$conf{privacy_text};
    $status->{configuration}->{force_toolkit_name}=$conf{force_toolkit_name} || 0;
    $status->{configuration}->{allow_internal_addresses}=$conf{allow_internal_addresses} || 0;

    $status->{ls_client_uuid} = get_client_uuid(file => '/var/lib/perfsonar/lsregistrationdaemon/client_uuid');

    my $logger = $self->{LOGGER};

    # Check whether globally registered
    if ($external_address) {
        eval {
            # Make sure it returns in a reasonable amount of time if reverse DNS
            # lookups are failing for some reason.
            local $SIG{ALRM} = sub { die "Timeout" };
            alarm(5);
            $is_registered = is_host_registered($external_address);
            alarm(0);
        };
        if($@){
            $logger->error("Unable to find host record in LS using $external_address: $@");
        }elsif($is_registered){
            $logger->error("Found host record in LS using $external_address");
        }else{
            $logger->error("Unable to find host record in LS using $external_address");
        }
    }

    #try hostname if not registered
    unless($is_registered){
        my $hostname = ""; 
        eval{
            local $SIG{ALRM} = sub { die "Timeout" };
            alarm(5);
            $hostname = hostname;
            $is_registered = is_host_registered(hostname);
            alarm(0);
        };
        if($@){
            $logger->error("Unable to find host record in LS using hostname " . ( $hostname ? $hostname : "hostname" ) . ": $@");
        }elsif($is_registered){
            $logger->error("Found host record in LS using $hostname");
        }else{
            $logger->error("Unable to find host record in LS using hostname " . ( $hostname ? $hostname : "hostname" ));
        }
    }

    $status->{globally_registered} = $is_registered;

    my $toolkit_rpm_version;

    # Make use of the fact that the config daemon is contained in the Toolkit RPM.
    my $config_daemon = get_service_object("config_daemon");
    if ($config_daemon) {
        $toolkit_rpm_version = $config_daemon->package_version;
    }
    $status->{toolkit_version} = $toolkit_rpm_version;
    
    # round to nearest GB (LS rounds to MB)
    # Note: Make sure this is before NTP call because the NTP call breaks sleep
    $status->{host_memory} = int(get_health_info()->{memstats}->{memtotal}/1024/1024 + .5);
    
    my $ntp = get_service_object("ntp");
    $status->{ntp}->{synchronized} = $ntp->is_synced();

    # get OS info
    my $os_info = get_operating_system_info();
    $status->{distribution} = $os_info->{distribution_name} . " " . $os_info->{distribution_version};

    # get CPU info
    my $cpu_info = get_processor_info();
    $status->{cpus} = $cpu_info->{count};
    $status->{cpu_cores} = $cpu_info->{cores};
    $status->{cpu_speed} = $cpu_info->{speed};

    # get more Host info
    my $host_info = get_dmi_info();
    $status->{is_vm} = $host_info->{is_virtual_machine};
    $status->{product_name} = $host_info->{product_name};
    $status->{sys_vendor} = $host_info->{sys_vendor};

    # add parameters that need authentication
    if($self->{authenticated}){
        $status->{kernel_version} = $os_info->{kernel_version};
        if(is_auto_updates_on()){
            $status->{auto_updates} = 1; 
        }else{
            $status->{auto_updates} = 0;
        }

    }


    # get TCP info
    my $tcp_info = get_tcp_configuration();
    $status->{tcp_info} = $tcp_info;

    return $status;

}

sub get_ntp_information{

    my $self = shift;
    my $response = get_ntp_info();
    my $ntp = get_service_object("ntp");
    $response->{synchronized} = $ntp->is_synced() || 0;
    return $response;

}

sub get_services {
    my $self = shift;
    my $caller = shift;
    my $params = $caller->{'input_params'};

    my %conf = %{$self->{config}};
    my $owamp_config = $conf{'owamp_config'};
    my $owamp_limits = $conf{'owamp_limits'};

    my @owamp_test_ports = ();
    my $owampd_cfg = perfSONAR_PS::NPToolkit::Config::OWAMP->new( );
    $owampd_cfg->init( { owampd_limits => $owamp_limits, owampd_conf => $owamp_config  } ) ;

    my ($status, $res) = $owampd_cfg->get_test_port_range();
    if ($status == 0) {
        push @owamp_test_ports, {
            type => "test",
            min_port => $res->{min_port},
            max_port => $res->{max_port},
        };
    }
    else {
        # OWAMP's peer range defaults to "any port"
        push @owamp_test_ports, {
            type => "test",
            min_port => 1,
            max_port => 65535,
        };
    }
    
    my $twamp_config = $conf{'twamp_config'};
    my $twamp_limits = $conf{'twamp_limits'};

    my @twamp_test_ports = ();
    my $twampd_cfg = perfSONAR_PS::NPToolkit::Config::TWAMP->new( );
    $twampd_cfg->init( { twampd_limits => $twamp_limits, twampd_conf => $twamp_config  } ) ;

    ($status, $res) = $twampd_cfg->get_test_port_range();
    if ($status == 0) {
        push @twamp_test_ports, {
            type => "test",
            min_port => $res->{min_port},
            max_port => $res->{max_port},
        };
    }
    else {
        # OWAMP's peer range defaults to "any port"
        push @twamp_test_ports, {
            type => "test",
            min_port => 1,
            max_port => 65535,
        };
    }

    my @service_names = qw(owamp twamp psconfig pscheduler esmond lsregistration);
    my %services = ();
    foreach my $service_name ( @service_names ) {
        my $service = get_service_object($service_name);

        $self->{LOGGER}->debug("Checking ".$service_name);
      #   my $is_running = $service->check_running();
          my $is_running = "no";

        my $daemon_port = -1;
        my @addr_list;
        if ($service->can("get_addresses")) {
            @addr_list = @{$service->get_addresses()};
            if (@addr_list > 0) {
                my @del_indexes = reverse(grep { $addr_list[$_] =~ /^tcp/ } 0..$#addr_list);
                foreach my $index (@del_indexes) {
                    #$service->{'daemon_port'} = _get_port_from_url($addr_list[$index]);
                    $daemon_port = $self->_get_port_from_url($addr_list[$index]);
                    splice (@addr_list, $index, 1);
                }
            }
        }

        my $is_running_output = ($is_running)?"yes":"no";

        if ($service->disabled) {
            $is_running_output = "disabled" unless $is_running;
        }
        my $is_installed;
        if ( $service->can('is_installed') ) {
            $is_installed = $service->is_installed();
        }

        my $enabled = (not $service->disabled) || 0;

        my $display_name = $service_name;
        $display_name =~ s/_/-/g;

        my %service_info = ();
        $service_info{"name"}          = $display_name;
        $service_info{"enabled"}       = $enabled;
        $service_info{"is_running"}    = $is_running_output;
        $service_info{"is_installed"}  = $is_installed if (defined $is_installed);
        $service_info{"daemon_port"}   = $daemon_port if ($daemon_port != -1);
        $service_info{"addresses"}     = \@addr_list;
        $service_info{"version"}       = $service->package_version;

        if ($service_name eq "owamp") {
            $service_info{"testing_ports"} = \@owamp_test_ports;
        }elsif ($service_name eq "twamp") {
            $service_info{"testing_ports"} = \@twamp_test_ports;
        }

        $services{$service_name} = \%service_info;
    }


    my @services = sort {$a->{name} cmp $b->{name}} values %services;

    return {'services', \@services};
}

sub update_auto_updates {
    my $self = shift;
    my $caller = shift;
    my $params = $caller->{'input_params'};

    # The "auto updates" are turned on and off by enabling/disabling the 'yum_cron' service
    my $name = 'yum_cron';
    my $enabled = $params->{'enabled'}->{'value'};

    my ($res, $message);
    my $success = 1;

    my $logger = $self->{LOGGER};

    unless (get_service_object($name)) {
        $logger->error("Service $name not found");
        return { error => "Error configuring auto updates" };
    }

    if ($enabled == 1) {
        $res = start_service( { name => $name, enable => 1 });
        $message = "Auto updates succesfully enabled";
    } else {
        $res = stop_service( { name => $name, disable => 1 });
        $message = "Auto updates succesfully disabled";
    }

    $success = 0 if ($res != 0);

    my %resp;

    if ($success) {
        %resp = ( message => $message );
    }
    else {
        %resp = ( error => "Error while configuring auto updates, configuration NOT saved. Please consult the logs for more information.");
    }
    
    return \%resp;

}

sub _get_port_from_url {
    my $self = shift;
    my $url = shift;
    my $port = -1;
    if ($url =~ m|tcp://.+:(\d+)|) {
        $port = $1;
    }
    return $port;

}

sub get_summary {
    my $self = shift;

    my $start_time = gettimeofday();
    my $end_time;


    my $comm_obj = perfSONAR_PS::NPToolkit::DataService::Communities->new( {config_file => $self->{config_file}, load_ls_registration => 1 } );

    my $administrative_info = $self->get_metadata();
    #my $administrative_info = $self->get_admin_information();
    my $status = $self->get_details();
    my $services = $self->get_services();
    my $communities = $comm_obj->get_host_communities();
    my $templates = $self->get_templates();

    my $ntp_info = {'ntp' => ( $self->get_ntp_information() || {} ) };


    my $results = { %$administrative_info, %$status, %$services, %$communities, %$templates, %$ntp_info };

    return $results;

}

sub get_templates {
    my $self = shift;
    my @template_urls = ();
    eval {
        #get file
        my $config_file = '/etc/perfsonar/psconfig/pscheduler-agent.json';
        my $agent_conf_client = new perfSONAR_PS::PSConfig::PScheduler::ConfigConnect(
            url => $config_file
        );
        if($agent_conf_client->error()){
            die "Error opening $config_file: " . $agent_conf_client->error();
        } 
        #parse config
        my $agent_conf = $agent_conf_client->get_config();
        if($agent_conf_client->error()){
            die "Error parsing $config_file: " . $agent_conf_client->error();
        }
        #validate config
        my @agent_conf_errors = $agent_conf->validate();
        if(@agent_conf_errors){
            my $err = "$config_file is not valid. The following errors were encountered: \n";
            foreach my $error(@agent_conf_errors){
                $err .= "    JSON Path: " . $error->path . "\n";
                $err .= "    Error: " . $error->message . "\n";
            }
            die $err;
        }
        #load urls into array
        foreach my $remote(@{$agent_conf->remotes()}){
            push @template_urls, $remote->url();
        }
    };
    if ($@) {
        $self->{LOGGER}->error("Error reading pSConfig template URLs: " . $@);
        @template_urls = [];
    }
    return {templates => \@template_urls};
}

sub get_system_health {
    my $self = shift;

    my $caller = shift;

    $self->{authenticated} = $caller->{authenticated};
    my $health = get_health_info();
   
    my $multiplier = 1024; # the underlying service returns RAM/disk in kilobytes, we want bytes

    my $result = ();

    if($self->{authenticated}){
        $result->{'cpu_util'} = $health->{'cpustats'}->{'cpu'}->{'total'};
        $result->{'mem_used'} = $health->{'memstats'}->{'memused'} * $multiplier;
        $result->{'swap_used'} = $health->{'memstats'}->{'swapused'} * $multiplier;
        $result->{'load_avg'}= $health->{'loadavg'};
    }
    
    $result->{'mem_total'}= $health->{'memstats'}->{'memtotal'} * $multiplier;
   
    $result->{'swap_total'} = $health->{'memstats'}->{'swaptotal'} * $multiplier;
    

    #disk usage
    my $disk = $health->{'diskusage'};

    foreach my $key (keys %$disk){
        if ($disk->{$key}->{"mountpoint"} eq "/"){ 
            if($self->{authenticated}){
                $result->{"rootfs"}->{"used"}= $disk->{$key}->{"usage"} * $multiplier;
            }
             $result->{"rootfs"}->{"total"} = $disk->{$key}->{"total"} * $multiplier;
             last;
        }
    }
    return $result;

}


1;

# vim: expandtab shiftwidth=4 tabstop=4
