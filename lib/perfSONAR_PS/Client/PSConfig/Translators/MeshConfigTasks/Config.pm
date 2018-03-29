package perfSONAR_PS::Client::PSConfig::Translators::MeshConfigTasks::Config;

use Mouse;

use perfSONAR_PS::Client::PSConfig::Archive;
use perfSONAR_PS::Client::PSConfig::Addresses::Address;
use perfSONAR_PS::Client::PSConfig::Addresses::AddressLabel;
use perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddress;
use perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel;
use perfSONAR_PS::Client::PSConfig::Host;
use perfSONAR_PS::Client::PSConfig::Config;
use perfSONAR_PS::Client::PSConfig::Schedule;
use perfSONAR_PS::Client::PSConfig::Task;
use perfSONAR_PS::Client::PSConfig::Test;
use perfSONAR_PS::Client::PSConfig::Translators::MeshConfig::Schema qw(meshconfig_json_schema);
use perfSONAR_PS::Utils::DNS qw(discover_source_address);
use perfSONAR_PS::Utils::Host qw(get_interface_addresses_by_type);

use Data::Validate::Domain qw(is_hostname);
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use Net::IP;

use JSON::Validator;
use URI;
use JSON;
use DateTime;
use Config::General qw(ParseConfig);
use Data::Dumper;

use constant META_DISPLAY_NAME => 'display-name';

extends 'perfSONAR_PS::Client::PSConfig::Translators::BaseTranslator';

has 'use_archive_details' => (is => 'rw', isa => 'Bool', default => sub { 0 });
has 'save_global_archives' => (is => 'rw', isa => 'Bool', default => sub { 0 });
has 'global_archive_dir' => (is => 'rw', isa => 'Str', default => sub { '/etc/perfsonar/psconfig/archives.d/' });
has 'disable_bwctl' => (is => 'rw', isa => 'Bool', default => sub { 0 });
has 'include_added_by_mesh' => (is => 'rw', isa => 'Bool', default => sub { 0 });

=item name()

Returns name of translator

=cut

sub name {
    return 'meshconfig-agent-tasks.conf';
}

=item can_translate()

Determines if given JSON object can be converted to MeshConfig format, if can prepare object
for translation

=cut


sub can_translate {
    my ($self, $raw_config, $json_obj) = @_;
    
    #this config is not JSON
    return 0 if($json_obj || !$raw_config);
    
    #clear errors
    $self->_set_error('');

    #try to read
    my $config = $self->_load_config($raw_config);
    return 0 unless($config);
    
    #looks good  
    return 1;
}

=item translate()

Translates MeshConfig file to pSConfig format

=cut

sub translate {
    my ($self, $raw_config, $json_obj) = @_;
    
    #clear errors
    $self->_set_error('');
    
    #First validate this config
    my $config = $self->_load_config($raw_config);
    return unless($config);
    #convert tests to array
    unless(ref($config->{'test'}) eq 'ARRAY'){
        $config->{'test'} = [ $config->{'test'} ];
    }
    #set to data
    $self->data($config);
    
    
    #init translation
    my $psconfig = new perfSONAR_PS::Client::PSConfig::Config();
    
    #set description
    my $now=DateTime->now;
    $now->set_time_zone("UTC");
    my $iso_now = $now->ymd('-') . 'T' . $now->hms(':') . '+00:00';
    my $top_meta = {
        "psconfig-translation" => {
            "source-format" => 'mesh-config-tasks-conf',
            "time-translated" => $iso_now
        }
    };
    #set meta
    $psconfig->psconfig_meta($top_meta);
    
    #convert default parameters
    my $default_test_params = {};
    if($self->data()->{'default_parameters'}){
        unless(ref($self->data()->{'default_parameters'}) eq 'ARRAY'){
            $self->data()->{'default_parameters'} = [ $self->data()->{'default_parameters'} ];
        }
        foreach my $default_test_param(@{$self->data()->{'default_parameters'}}){
            my $type = $default_test_param->{'type'};
            next unless($type);
            my $params = {};
            foreach my $param_key(keys %{$default_test_param}){
                next if($param_key eq 'type');
                $params->{$param_key} = $default_test_param->{$param_key};
            }
            $default_test_params->{$type} = $params;
        }
    }
    
    #iterate through tests and build psconfig tasks
    foreach my $test(@{$self->data()->{'test'}}){
        #skip tests added by mesh
        next if($test->{'added_by_mesh'} && !$self->include_added_by_mesh());
        
        #inherit default parameters
        next unless($test->{'parameters'});
        if($default_test_params->{$test->{'parameters'}->{'type'}}){
            foreach my $param_key(keys %{$default_test_params->{$test->{'parameters'}->{'type'}}}){
                next if($param_key eq 'type');
                $test->{'parameters'}->{$param_key} = $default_test_params->{$test->{'parameters'}->{'type'}}->{$param_key};
            }
        }
        
        #build psconfig tasks
        $self->_convert_tasks($test, $psconfig);
    }
    
    #convert and save global archives
    if($self->save_global_archives()){
        my $global_archive_psconfig = new perfSONAR_PS::Client::PSConfig::Config();
        my $global_archive_refs = {};
        $self->_convert_measurement_archives($self->data(), $global_archive_psconfig, $global_archive_refs);
        foreach my $global_archive_ref(keys %{$global_archive_refs}){
            my $global_archive = $global_archive_psconfig->archive($global_archive_ref);
            next unless($global_archive_ref);
            $self->save_archive($global_archive, $global_archive_ref, {pretty => 1});
        }
    }
    
    #check if we actually have anything we converted - if all remote mesh we may not
    unless(@{$psconfig->task_names()}){
        $self->_set_error("Nothing to convert. This is not an error if all tests contain added_by_mesh. Ignore any errors above about malformed JSON string.");
        return;
    }
    
    #build pSConfig Object and validate
    my @errors = $psconfig->validate();
    if(@errors){
        my $err = "Generate PSConfig JSON is not valid. Encountered the following validation errors:\n\n";
        foreach my $error(@errors){
            $err .= "   Node: " . $error->path . "\n";
            $err .= "   Error: " . $error->message . "\n\n";
        }
        $self->_set_error($err);
        return;
    }
    
    return $psconfig;
}

=item _load_config()

Loads config and does simple validation

=cut

sub _load_config {
    my ($self, $raw_config) = @_;
    
    #load from file
    my %config;
    eval {
        %config = ParseConfig(-String => $raw_config, -UTF8 => 1);
    };
    if ($@) {
        return;
    }
    
    #validate
    unless($config{'test'}){
        return;
    }
    
    return \%config;
}

sub _convert_measurement_archives {
    my ($self, $obj, $psconfig, $archive_refs) = @_;
    
    return unless($obj->{'measurement_archive'});
    #convert tests to array
    unless(ref($obj->{'measurement_archive'}) eq 'ARRAY'){
        $obj->{'measurement_archive'} = [ $obj->{'measurement_archive'} ];
    }
    
    foreach my $ma(@{$obj->{'measurement_archive'}}){
        next unless($ma->{'database'} || $ma->{'public_url'});
        next unless($ma->{'type'});
        chomp $ma->{'type'};
        my $archive_test_type = '';
        if($ma->{'type'} =~ /^esmond\/(.+)/){
            $archive_test_type = $1;
        }else{
            next;
        }
        next if($ma->{added_by_mesh} && !$self->include_added_by_mesh());
        
        # build URL
        my $url_obj = new URI($ma->{'public_url'} ? $ma->{'public_url'} : $ma->{'database'});
        my $archive_name = $url_obj->host;
        chomp $archive_name;
        # replace localhost archive with scheduled_by_address since localhost causes 
        # problems when remote is lead
        if($archive_name eq 'localhost' || $archive_name eq '127.0.0.1' || $archive_name eq '::1'){
            $archive_name = 'esmond_local';
            $url_obj->host('scheduled_by_address');
        }
        next unless($archive_name);
         
        my $archive = new perfSONAR_PS::Client::PSConfig::Archive();
        $archive->archiver('esmond');
        #set template variable here if needed so special chars not escaped
        my $db_url =  $url_obj . '';
        $db_url =~ s/scheduled_by_address/{% scheduled_by_address %}/g; 
        $archive->archiver_data_param('url', $db_url);
        if($ma->{'password'}){
            $archive->archiver_data_param('_auth-token', $ma->{'password'});
        }
        $archive->archiver_data_param('measurement-agent', '{% scheduled_by_address %}');
        # retry policy
        if($self->use_archive_details() && $ma->{'retry_policy'}){
            if($ma->{'retry_policy'}->{'ttl'}){
                $archive->ttl($self->_seconds_to_iso($ma->{'retry_policy'}->{'ttl'}));
            }
            if($ma->{'retry_policy'}->{'retry'}){
                my $retry_policy = [];
                if(ref($ma->{'retry_policy'}->{'retry'}) ne 'ARRAY'){
                    $ma->{'retry_policy'}->{'retry'} = [ $ma->{'retry_policy'}->{'retry'} ];
                }
                foreach my $retry(@{$ma->{'retry_policy'}->{'retry'}}){
                    my $retry_obj = {
                        'attempts' => int($retry->{'attempts'}),
                        'wait' => $self->_seconds_to_iso($retry->{'wait'})
                    };
                    push @{$retry_policy}, $retry_obj;
                }
                $archive->archiver_data_param('retry-policy', $retry_policy);
            }
        }
        # convert summaries if asked
        if($self->use_archive_details() && $ma->{'summary'}){
            my $summaries = [];
            if(ref($ma->{'summary'}) ne 'ARRAY'){
                $ma->{'summary'} = [ $ma->{'summary'} ];
            }
            foreach my $summary(@{$ma->{'summary'}}){
                my $summary_obj = {
                    'summary-type' => $summary->{'summary_type'},
                    'event-type' => $summary->{'event_type'},
                    'summary-window' => $summary->{'summary_window'},
                };
                push @{$summaries}, $summary_obj;
            }
            $archive->archiver_data_param('summaries', $summaries);
        }
    
        # by default intentionally use name that could overwrite variations of same URL since lots
        # of unnecessarily inconsistent things in old code
        if($self->use_archive_details()){
            $archive_name .= '__' . $archive->checksum();
        }
        $archive_refs->{$archive_name} = 1;
        next if($psconfig->archive($archive_name));
        
        #add archive
        $psconfig->archive($archive_name, $archive);
    }
}

sub _convert_schedule {
    my ($self, $schedule_params) = @_;
    
    return unless($schedule_params->{'type'} eq 'regular_intervals');
    
    my $psconfig_schedule = new perfSONAR_PS::Client::PSConfig::Schedule();
    
    #schedule params - not all of these are consistent so not moving to function
    $psconfig_schedule->repeat($self->_seconds_to_iso($schedule_params->{'interval'})) if($schedule_params->{'interval'});
    if($schedule_params->{'slip'}){
        $psconfig_schedule->slip($self->_seconds_to_iso($schedule_params->{'slip'}));
    }elsif($schedule_params->{'random_start_percentage'} && $schedule_params->{'interval'}){
        if($schedule_params->{'interval'} > 43200){
            $psconfig_schedule->slip($self->_seconds_to_iso(43200));
        }else{
            $psconfig_schedule->slip($self->_seconds_to_iso($schedule_params->{'interval'}));
        }
    }
    $psconfig_schedule->sliprand(1) unless(defined $schedule_params->{'slip_randomize'} && !$schedule_params->{'slip_randomize'});
    
    return $psconfig_schedule;
}

sub _convert_reference {
    my ($self, $reference_params, $psconfig_task) = @_;
    
    return unless($reference_params);
    
    unless(ref($reference_params) eq 'ARRAY'){
        $reference_params = [ $reference_params ];
    }
    
    foreach my $reference(@{$reference_params}){
        if($reference->{'name'} && defined $reference->{'value'}){
            $psconfig_task->reference_param($reference->{'name'}, $reference->{'value'});
        }
    }
}


sub convert_bwctl {
    my ($self, $test_params, $force_ipv4, $force_ipv6) = @_;
    
    #build test
    my $psconfig_test = new perfSONAR_PS::Client::PSConfig::Test();
    
    #test type
    $psconfig_test->type("throughput");
    
    #tool
    my @tools = ();
    if($test_params->{'tool'}){
        my @tmp_tools = split ",", $test_params->{'tool'};
        foreach my $tool(@tmp_tools){
            chomp $tool;
            $tool =~ s/^bwctl\///;
            unless($self->disable_bwctl()){
                if($tool eq 'iperf'){
                    push @tools, 'bwctliperf2';
                }elsif($tool eq 'iperf3'){
                    push @tools, 'bwctliperf3';
                }
            }
            push @tools, $tool;
            
        }
    }
    
    #test params (template)
    $psconfig_test->spec_param('source', '{% address[0] %}');
    $psconfig_test->spec_param('dest', '{% address[1] %}');
    $psconfig_test->spec_param('source-node', '{% pscheduler_address[0] %}');
    $psconfig_test->spec_param('dest-node', '{% pscheduler_address[1] %}');
    #test params (duration)
    $psconfig_test->spec_param('duration', $self->_seconds_to_iso($test_params->{'duration'})) if($test_params->{'duration'});
    $psconfig_test->spec_param('omit', $self->_seconds_to_iso($test_params->{'omit_interval'})) if($test_params->{'omit_interval'});
    #test params (int)
    $psconfig_test->spec_param('parallel', int($test_params->{'streams'})) if(defined $test_params->{'streams'});
    $psconfig_test->spec_param('ip-tos', int($test_params->{'packet_tos_bits'})) if(defined $test_params->{'packet_tos_bits'});
    $psconfig_test->spec_param('buffer-length', int($test_params->{'buffer_length'})) if(defined $test_params->{'buffer_length'});
    $psconfig_test->spec_param('window-size', int($test_params->{'window_size'})) if(defined $test_params->{'window_size'});
    $psconfig_test->spec_param('client-cpu-affinity', int($test_params->{'client_cpu_affinity'})) if(defined $test_params->{'client_cpu_affinity'});
    $psconfig_test->spec_param('server-cpu-affinity', int($test_params->{'server_cpu_affinity'})) if(defined $test_params->{'server_cpu_affinity'});
    $psconfig_test->spec_param('flow-label', int($test_params->{'flow_label'})) if(defined $test_params->{'flow_label'});
    $psconfig_test->spec_param('mss', int($test_params->{'mss'})) if(defined $test_params->{'mss'});
    $psconfig_test->spec_param('dscp', int($test_params->{'dscp'})) if(defined $test_params->{'dscp'});
    #test params (boolean)
    $psconfig_test->spec_param('no-delay', JSON::true) if($test_params->{'no_delay'});
    $psconfig_test->spec_param('zero-copy', JSON::true) if($test_params->{'zero_copy'});
    $psconfig_test->spec_param('reverse', JSON::true) if($test_params->{'local_firewall'});
    #test params (string)
    $psconfig_test->spec_param('congestion', $test_params->{'congestion'}) if($test_params->{'congestion'});
    #test param (ip version)
    $psconfig_test->spec_param('ip-version', 4) if($force_ipv4);
    $psconfig_test->spec_param('ip-version', 6) if($force_ipv6);
    #test params (protocol)
    if($test_params->{'use_udp'}){
        $psconfig_test->spec_param('udp', JSON::true);
        $psconfig_test->spec_param('bandwidth', int($test_params->{'udp_bandwidth'})) if($test_params->{'udp_bandwidth'});
    }elsif($test_params->{'tcp_bandwidth'}){
        $psconfig_test->spec_param('bandwidth', int($test_params->{'tcp_bandwidth'}));
    }
    
    return $psconfig_test, \@tools;
}

sub convert_powstream {
    my ($self, $test_params, $force_ipv4, $force_ipv6) = @_;
    
    #build test
    my $psconfig_test = new perfSONAR_PS::Client::PSConfig::Test();
    
    #test type
    $psconfig_test->type("latencybg");
    
    #test params (template)
    $psconfig_test->spec_param('source', '{% address[0] %}');
    $psconfig_test->spec_param('dest', '{% address[1] %}');
    $psconfig_test->spec_param('source-node', '{% pscheduler_address[0] %}');
    $psconfig_test->spec_param('dest-node', '{% pscheduler_address[1] %}');
    $psconfig_test->spec_param('flip', '{% flip %}');
    #test params (int)
    $psconfig_test->spec_param('packet-count', int($test_params->{'resolution'})) if(defined $test_params->{'resolution'});
    $psconfig_test->spec_param('ip-tos', int($test_params->{'packet_tos_bits'})) if(defined $test_params->{'packet_tos_bits'});
    $psconfig_test->spec_param('packet-padding', int($test_params->{'packet_length'})) if(defined $test_params->{'packet_length'});
    #test params (numeric)
    $psconfig_test->spec_param('packet-interval', $test_params->{'inter_packet_time'} * 1.0) if(defined $test_params->{'inter_packet_time'});
    #test param (ip version)
    $psconfig_test->spec_param('ip-version', 4) if($force_ipv4);
    $psconfig_test->spec_param('ip-version', 6) if($force_ipv6);
    #test params (boolean)
    $psconfig_test->spec_param('output-raw', JSON::true) if($test_params->{'output_raw'});
    #range
    if($test_params->{'receive_port_range'}){
        my @range_vals = split '-', $test_params->{'receive_port_range'};
        if(@range_vals == 2){
            eval {
                $psconfig_test->spec_param('data-ports', {
                    'lower' => int($range_vals[0]),
                    'upper' => int($range_vals[1])
                });
            };
        }
    }
    
    return $psconfig_test, [];
}

sub convert_bwping {
    my ($self, $test_params, $force_ipv4, $force_ipv6) = @_;
    
    #build test
    my $psconfig_test = new perfSONAR_PS::Client::PSConfig::Test();
    
    #test type
    $psconfig_test->type("rtt");
        
    #test params (template)
    $psconfig_test->spec_param('source', '{% address[0] %}');
    $psconfig_test->spec_param('dest', '{% address[1] %}');
    $psconfig_test->spec_param('source-node', '{% pscheduler_address[0] %}');
    #test params (int)
    $psconfig_test->spec_param('count', int($test_params->{'packet_count'})) if(defined $test_params->{'packet_count'});
    $psconfig_test->spec_param('length', int($test_params->{'packet_length'})) if(defined $test_params->{'packet_length'});
    $psconfig_test->spec_param('ttl', int($test_params->{'packet_ttl'})) if(defined $test_params->{'packet_ttl'});
    $psconfig_test->spec_param('ip-tos', int($test_params->{'packet_tos_bits'})) if(defined $test_params->{'packet_tos_bits'});
    $psconfig_test->spec_param('flowlabel', int($test_params->{'flowlabel'})) if(defined $test_params->{'flowlabel'});
    $psconfig_test->spec_param('deadline', int($test_params->{'deadline'})) if(defined $test_params->{'flowlabel'});
    #test param (ip version)
    $psconfig_test->spec_param('ip-version', 4) if($force_ipv4);
    $psconfig_test->spec_param('ip-version', 6) if($force_ipv6);
    #test params (boolean)
    $psconfig_test->spec_param('hostnames', JSON::true) if($test_params->{'hostnames'});
    $psconfig_test->spec_param('suppress-loopback', JSON::true) if($test_params->{'suppress_loopback'});
    #test params (duration)
    $psconfig_test->spec_param('interval', $self->_seconds_to_iso($test_params->{'inter_packet_time'})) if($test_params->{'inter_packet_time'});
    $psconfig_test->spec_param('deadline', $self->_seconds_to_iso($test_params->{'deadline'})) if($test_params->{'deadline'});
    $psconfig_test->spec_param('timeout', $self->_seconds_to_iso($test_params->{'timeout'})) if($test_params->{'timeout'});
    
    return $psconfig_test, [];
}

sub convert_bwping_owamp {
    my ($self, $test_params, $force_ipv4, $force_ipv6) = @_;
    
    #build test
    my $psconfig_test = new perfSONAR_PS::Client::PSConfig::Test();
    
    #test type
    $psconfig_test->type("latency");
    
    #test params (template)
    $psconfig_test->spec_param('source', '{% address[0] %}');
    $psconfig_test->spec_param('dest', '{% address[1] %}');
    $psconfig_test->spec_param('source-node', '{% pscheduler_address[0] %}');
    $psconfig_test->spec_param('dest-node', '{% pscheduler_address[1] %}');
    $psconfig_test->spec_param('flip', '{% flip %}');
    #test params (int)
    $psconfig_test->spec_param('packet-count', int($test_params->{'packet_count'})) if(defined $test_params->{'packet_count'});
    $psconfig_test->spec_param('ip-tos', int($test_params->{'packet_tos_bits'})) if(defined $test_params->{'packet_tos_bits'});
    $psconfig_test->spec_param('packet-padding', int($test_params->{'packet_length'})) if(defined $test_params->{'packet_length'});
    #test params (numeric)
    $psconfig_test->spec_param('packet-interval', $test_params->{'inter_packet_time'} * 1.0) if(defined $test_params->{'inter_packet_time'});
    #test param (ip version)
    $psconfig_test->spec_param('ip-version', 4) if($force_ipv4);
    $psconfig_test->spec_param('ip-version', 6) if($force_ipv6);
    #test params (boolean)
    $psconfig_test->spec_param('output-raw', JSON::true) if($test_params->{'output_raw'});
    
    return $psconfig_test, [];
}


sub convert_simplestream {
    my ($self, $test_params, $force_ipv4, $force_ipv6) = @_;
    
    #build test
    my $psconfig_test = new perfSONAR_PS::Client::PSConfig::Test();
    
    #test type
    $psconfig_test->type("simplestream");
    
    #tool
    my @tools = ();
    if($test_params->{'tool'}){
        my @tmp_tools = split ",", $test_params->{'tool'};
        foreach my $tool(@tmp_tools){
            chomp $tool;
            $tool =~ s/^bwctl\///;
            push @tools, $tool;
        }
    }
        
    #test params (template)
    $psconfig_test->spec_param('source', '{% address[0] %}');
    $psconfig_test->spec_param('dest', '{% address[1] %}');
    $psconfig_test->spec_param('source-node', '{% pscheduler_address[0] %}');
    $psconfig_test->spec_param('dest-node', '{% pscheduler_address[1] %}');
    #test params (duration)
    $psconfig_test->spec_param('dawdle', $self->_seconds_to_iso($test_params->{'dawdle'})) if($test_params->{'dawdle'});
    $psconfig_test->spec_param('timeout', $self->_seconds_to_iso($test_params->{'timeout'})) if($test_params->{'timeout'});
    #test params (numeric)
    $psconfig_test->spec_param('fail', $test_params->{'fail'} * 1.0) if(defined $test_params->{'fail'});
    #test params (string)
    $psconfig_test->spec_param('test-material', $test_params->{'test_material'}) if($test_params->{'test_material'});
    #test param (ip version)
    $psconfig_test->spec_param('ip-version', 4) if($force_ipv4);
    $psconfig_test->spec_param('ip-version', 6) if($force_ipv6);
    
    return $psconfig_test, \@tools;
}

sub convert_bwtraceroute {
    my ($self, $test_params, $force_ipv4, $force_ipv6) = @_;
    
    #build test
    my $psconfig_test = new perfSONAR_PS::Client::PSConfig::Test();
    
    #test type
    $psconfig_test->type("trace");
    
    #tool
    my @tools = ();
    if($test_params->{'tool'}){
        my @tmp_tools = split ",", $test_params->{'tool'};
        foreach my $tool(@tmp_tools){
            chomp $tool;
            $tool =~ s/^bwctl\///;
            unless($self->disable_bwctl()){
                if($tool eq 'traceroute'){
                    push @tools, 'bwctltraceroute';
                }elsif($tool eq 'tracepath'){
                    push @tools, 'bwctltracepath';
                }
            }
            push @tools, $tool;
        }
    }
        
    #test params (template)
    $psconfig_test->spec_param('source', '{% address[0] %}');
    $psconfig_test->spec_param('dest', '{% address[1] %}');
    $psconfig_test->spec_param('source-node', '{% pscheduler_address[0] %}');
    
    #test params (int)
    $psconfig_test->spec_param('length', int($test_params->{'packet_length'})) if(defined $test_params->{'packet_length'});
    $psconfig_test->spec_param('first-ttl', int($test_params->{'packet_first_ttl'})) if(defined $test_params->{'packet_first_ttl'});
    $psconfig_test->spec_param('hops', int($test_params->{'packet_max_ttl'})) if(defined $test_params->{'packet_max_ttl'});
    $psconfig_test->spec_param('queries', int($test_params->{'queries'})) if(defined $test_params->{'queries'});
    $psconfig_test->spec_param('ip-tos', int($test_params->{'packet_tos_bits'})) if(defined $test_params->{'packet_tos_bits'});
    #test params (boolean)
    $psconfig_test->spec_param('as', JSON::true) if($test_params->{'as'});
    $psconfig_test->spec_param('fragment', JSON::true) if($test_params->{'fragment'});
    $psconfig_test->spec_param('hostnames', JSON::true) if($test_params->{'hostnames'});
    #test params (duration)
    ## deprecated version of wait
    $psconfig_test->spec_param('wait', $self->_seconds_to_iso($test_params->{'wait'})) if($test_params->{'wait'});
    ## deprecated version of sendwait
    $psconfig_test->spec_param('sendwait', $self->_seconds_to_iso($test_params->{'sendwait'})) if($test_params->{'sendwait'});
    #test param (ip version)
    $psconfig_test->spec_param('ip-version', 4) if($force_ipv4);
    $psconfig_test->spec_param('ip-version', 6) if($force_ipv6);
    #test params (string)
    $psconfig_test->spec_param('algorithm', $test_params->{'algorithm'}) if($test_params->{'algorithm'});
    $psconfig_test->spec_param('probe-type', $test_params->{'probe_type'}) if($test_params->{'probe_type'});
    
    return $psconfig_test, \@tools;
}

sub _copy_hashref {
    my ($self, $obj) = @_;
    
    my $new_obj = {};
    foreach my $k(keys %{$obj}){
        $new_obj->{$k} = $obj->{$k};
    }
    
    return $new_obj;
}

sub _seconds_to_iso {
    my ($self, $secs) = @_;
    
    $secs = int($secs);
    return "PT${secs}S";
}

sub _format_name {
    my ($self, $val) = @_;
    
    #replace spaces
    $val =~ s/\s/_/g;
    #replace invalid character
    $val =~ s/[^a-zA-Z0-9:._\\-]//g;
    
    return $val;
}

=item save_archive()

Saves archive file to disk

=cut

sub save_archive() {
    my ($self, $archive, $filename, $formatting_params) = @_;
    $formatting_params = {} unless $formatting_params;
    chomp $filename;
    $filename =~ s/^file:\/\///g;
    unless($filename) {
        $self->_set_error("No save_filename set");
        return;
    }
    
    my $full_filename = $self->global_archive_dir() . "${filename}.json";
    eval{
        open(my $fh, ">:encoding(UTF-8)", $full_filename) or die("Can't open $full_filename: $!");
        print $fh $archive->json($formatting_params);
        close $fh;
    };
    if($@){
        $self->_set_error($@);
    }
}

sub _convert_tasks{
    my ($self, $test, $psconfig) = @_;
    
    # SEE: perfSONAR_PS::RegularTesting::Tests::PSchedulerBase
    
    # get test name
    my $name = $test->{'description'} ? $test->{'description'} : "task";
    chomp $name;
    $name = $self->_format_name($name);
    my $i = 0;
    while($psconfig->test("${name}_${i}_0")){
        #nothing guarantees a unique description
        $i++;
    }
    $name = "${name}_${i}";
    
    #handle interface definitions, which pscheduler does not support
    my $interface_ips;
    if($test->{'local_interface'} && !$test->{'local_address'}){
        $interface_ips = get_interface_addresses_by_type(interface => $test->{'local_interface'});
        unless(@{$interface_ips->{ipv4_address}} || @{$interface_ips->{ipv6_address}}){
            $self->error("Unable to determine addresses for interface " . $test->{'local_interface'});
            return;
        }
    }
    
    #get archives
    my $archive_refs_map = {};
    $self->_convert_measurement_archives($test, $psconfig, $archive_refs_map);
    my @archive_refs = keys %{$archive_refs_map};
    
    #get schedule
    my $schedule =  $self->_convert_schedule($test->{'schedule'});
    $psconfig->schedule($name, $schedule) if($schedule);
    
    my %test_name_tracker = ();
    my $test_name_count = 0;
    my %exclude_tracker = ();
    foreach my $individual_test ($self->_get_individual_tests($test)) {
        my $force_ipv4        = $individual_test->{force_ipv4};
        my $force_ipv6        = $individual_test->{force_ipv6};
        my $test_parameters   = $individual_test->{test_parameters};
        
        #determine local address which is only complicated if interface specified
        my $parsed_target = $self->_parse_target($individual_test->{target}->{address});
        my ($local_address, $local_port, $source, $destination, $destination_port);
        if($interface_ips){
            my ($choose_status, $choose_res) = $self->_choose_endpoint_address(
                                                        $test->{'local_interface'},
                                                        $interface_ips, 
                                                        $parsed_target->{address},
                                                        $force_ipv4,
                                                        $force_ipv6,
                                                    );
            if($choose_status < 0){
                next;
            }else{
                $local_address = $choose_res;
            }
        }
        
        #now determine source and destination - again only complicated by interface names
        my $remote_address;
        unless($local_address){
            my $parsed_local = $self->_parse_target($test->{'local_address'});
            $local_address = $parsed_local->{address};
            $local_port = $parsed_local->{port};
        }
        if($individual_test->{receiver}){
            #if we are receiving, we have to know the local address
            if(!$local_address){
                #no interface or address given, try to get the routing tables to tell us
                $local_address = discover_source_address(address => $parsed_target->{address}, 
                                                            force_ipv4 => $force_ipv4,
                                                            force_ipv6 => $force_ipv6);
                #its ok if no local address, powstream can handle it
            }
            $source = $parsed_target->{address};
            $remote_address = $source;
            $destination = $local_address;
            $destination_port = $local_port;
        }else{
            #always set source so we don't end up with 127.0.0.1
            $local_address = discover_source_address(address => $parsed_target->{address}) unless($local_address);
            $source = $local_address;
            $destination = $parsed_target->{address};
            $remote_address = $destination;
            $destination_port = $parsed_target->{port};
        }
        
        #add local and remote to addresses 
        next unless($source && $destination && $local_address && $remote_address); #skips bad hostnames
        #create local address
        unless($psconfig->address($local_address)){
            my $psconfig_address = new perfSONAR_PS::Client::PSConfig::Addresses::Address();
            $psconfig_address->address($local_address);
            $psconfig->address($local_address, $psconfig_address);
        }
        #create remote address
        unless($psconfig->address($remote_address)){
            my $psconfig_address = new perfSONAR_PS::Client::PSConfig::Addresses::Address();
            $psconfig_address->address($remote_address);
            $psconfig_address->no_agent(1);
            $psconfig->address($remote_address, $psconfig_address);
        }
        
        #build test spec 
        my $psconfig_test;
        my $tools;
        if($test_parameters->{'type'} eq 'powstream'){
            ($psconfig_test, $tools) = $self->convert_powstream($test_parameters, $force_ipv4, $force_ipv6);
        }elsif($test_parameters->{'type'} eq 'bwctl'){
            ($psconfig_test, $tools) = $self->convert_bwctl($test_parameters, $force_ipv4, $force_ipv6);
        }elsif($test_parameters->{'type'} eq 'bwtraceroute'){
            ($psconfig_test, $tools) = $self->convert_bwtraceroute($test_parameters, $force_ipv4, $force_ipv6);
        }elsif($test_parameters->{'type'} eq 'bwping'){
            ($psconfig_test, $tools) = $self->convert_bwping($test_parameters, $force_ipv4, $force_ipv6);
        }elsif($test_parameters->{'type'} eq 'bwping/owamp'){
            ($psconfig_test, $tools) = $self->convert_bwping_owamp($test_parameters, $force_ipv4, $force_ipv6);
        }elsif($test_parameters->{'type'} eq 'simplestream'){
            ($psconfig_test, $tools) = $self->convert_simplestream($test_parameters, $force_ipv4, $force_ipv6);
        }
        next unless($psconfig_test);
        my $test_checksum = $psconfig_test->checksum();
        my $test_name;
        if($test_name_tracker{$test_checksum}){
            $test_name = $test_name_tracker{$test_checksum};
        }else{
            $test_name = $name . '_' . $test_name_count;
            $test_name_count++;
            $test_name_tracker{$test_checksum} = $test_name;
        }
        $psconfig->test($test_name, $psconfig_test) unless($psconfig->test($test_name));

        #determine group
        my $group_name = $test_name . '_' . $local_address;
        my $psconfig_group = $psconfig->group($group_name);
        unless($psconfig_group){
            $psconfig_group = new perfSONAR_PS::Client::PSConfig::Groups::Disjoint();
            my $a_sel = new perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel();
            $a_sel->name($local_address);
            $psconfig_group->add_a_address($a_sel);
            $psconfig->group($group_name, $psconfig_group);
            $exclude_tracker{$group_name} = {};
        }
        unless($exclude_tracker{$group_name}->{$remote_address}){
            #avoid adding duplicates
            my $b_sel = new perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel();
            $b_sel->name($remote_address);
            $psconfig_group->add_b_address($b_sel);
            $exclude_tracker{$group_name}->{$remote_address} = {};
        }
        if($remote_address eq $destination){
            $exclude_tracker{$group_name}->{$remote_address}->{'forward'} = 1;
        }else{
            $exclude_tracker{$group_name}->{$remote_address}->{'reverse'} = 1;
        }
        
        #build task if we needs it
        unless($psconfig->task($group_name)){
            my $psconfig_task = new perfSONAR_PS::Client::PSConfig::Task();
            $psconfig_task->group_ref($group_name);
            $psconfig_task->test_ref($test_name);
            $psconfig_task->schedule_ref($name) if($schedule);
            $psconfig_task->archive_refs(\@archive_refs) if(@archive_refs);
            if($tools){
                foreach my $tool(@{$tools}){
                    $psconfig_task->add_tool($tool);
                }
            }
            $self->_convert_reference($test->{'reference'}, $psconfig_task);
            $psconfig_task->psconfig_meta_param(META_DISPLAY_NAME(), $test->{'description'}) if($test->{'description'});
            $psconfig->task($test_name, $psconfig_task);
        }
    }
    
    #build exclude maps
    my %excl_pair_tracker = ();
    foreach my $excl_test_name(keys %exclude_tracker){
        my $group = $psconfig->group($excl_test_name);
        next unless($group); #should not happen
        my $local_address = $group->a_address(0)->name();
        next unless($local_address); #should not happen
        foreach my $remote_address(keys %{$exclude_tracker{$excl_test_name}}){
            my $remote_map = $exclude_tracker{$excl_test_name}->{$remote_address};
            unless($remote_map->{'forward'}){
                unless($excl_pair_tracker{$local_address}){
                    $excl_pair_tracker{$local_address} = new perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair();
                    my $sel = new perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel();
                    $sel->name($local_address);
                    $excl_pair_tracker{$local_address}->local_address($sel);
                    $group->add_exclude($excl_pair_tracker{$local_address});
                }
                my $sel = new perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel();
                $sel->name($remote_address);
                $excl_pair_tracker{$local_address}->add_target_address($sel);
            }
            unless($remote_map->{'reverse'}){
                unless($excl_pair_tracker{$remote_address}){
                    $excl_pair_tracker{$remote_address} = new perfSONAR_PS::Client::PSConfig::Groups::ExcludesAddressPair();
                    my $sel = new perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel();
                    $sel->name($remote_address);
                    $excl_pair_tracker{$remote_address}->local_address($sel);
                    $group->add_exclude($excl_pair_tracker{$remote_address});
                }
                my $sel = new perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel();
                $sel->name($local_address);
                $excl_pair_tracker{$remote_address}->add_target_address($sel);
            }
        }
    }
}

sub _parse_target {
    my ($self, $target) = @_;
    
    return { address => undef, port => undef } unless($target);
    
    my ($address, $port);

    if(is_ipv6($target)){
        $address = $target;
    }elsif(is_ipv4($target)){
        $address = $target;
    }elsif ($target =~ /^\[(.*)\]:(\d+)$/) {
        $address = $1;
        $port    = $2;
    }
    elsif ($target =~ /^\[(.*)\]$/) {
        $address = $1;
    }
    elsif ($target =~ /^(.*):(\d+)$/) {
        $address = $1;
        $port    = $2;
    }
    else {
        $address = $target;
    }

    return { address => $address, port => $port };
}
    
sub _choose_endpoint_address{
    my ($self, $ifname, $interface_ips, $target_address, $force_ipv4, $force_ipv6) = @_;
    my $local_address;
    
    #if an interface was given, figure out which address to use
    if($force_ipv4){
        unless(@{$interface_ips->{ipv4_address}}){
            return (-1, "No ipv4 address for interface " . $ifname . " but force_ipv4 enabled");
        }
        $local_address = $interface_ips->{ipv4_address}->[0]; #use first one in list
    }elsif($force_ipv6){
        unless(@{$interface_ips->{ipv6_address}}){
            return (-1, "No ipv6 address for interface " . $ifname . " but force_ipv6 enabled");
        }
        $local_address = $interface_ips->{ipv6_address}->[0]; #use first one in list
    }elsif(is_ipv4($target_address)){
        unless(@{$interface_ips->{ipv4_address}}){
            return (-1, "No ipv4 address for interface " . $ifname . " but target $target_address is IPv4");
        }
        $local_address = $interface_ips->{ipv4_address}->[0]; #use first one in list
    }elsif(is_ipv6($target_address)){
        unless(@{$interface_ips->{ipv6_address}}){
            return (-1, "No ipv6 address for interface " . $ifname . " but target $target_address is IPv6");
        }
        $local_address = $interface_ips->{ipv6_address}->[0]; #use first one in list
    }else{
        my @target_ips = resolve_address($target_address);
        my $ipv6;
        my $ipv4;
        foreach my $target_ip(@target_ips){
            if(is_ipv4($target_ip)){
                $ipv4 = $target_ip;
            }elsif(is_ipv6($target_ip)){
                $ipv6 = $target_ip;
            }
        }
        if($ipv6 && @{$interface_ips->{ipv6_address}}){
            $local_address = $interface_ips->{ipv6_address}->[0];
        }elsif($ipv4 && @{$interface_ips->{ipv4_address}}){
            $local_address = $interface_ips->{ipv4_address}->[0];
        }else{
            return (-1, "Unable to find a matching pair of IPv4 or IPv6 addresses for interface " . $ifname . " and target address $target_address"); 
        }
    }
    
    return (0, $local_address);
}

sub _get_individual_tests {
    my ($self, $test) = @_;
    my @tests = ();
    
    unless(ref($test->{'target'}) eq 'ARRAY' ){
        $test->{'target'} = [ $test->{'target'} ];
    }
    
    # Build the set of set of tests that make up this bwctl test
    foreach my $target (@{ $test->{'target'} }) {
        unless(ref($target) eq 'HASH' ){
            $target = { 'address' => $target };
        }
    
        my $target_parameters = $self->_get_target_parameters($target, $test->{'parameters'});

        unless ($target_parameters->{'send_only'}) {
            if (is_hostname($target->{'address'}) and $target_parameters->{'test_ipv4_ipv6'} and not $target_parameters->{'force_ipv4'} and not $target_parameters->{'force_ipv6'}) {
                push @tests, { target => $target, receiver => 1, force_ipv4 => 1, test_parameters => $target_parameters };
                push @tests, { target => $target, receiver => 1, force_ipv6 => 1, test_parameters => $target_parameters };
            }
            else {
                push @tests, {
                               target => $target,
                               receiver => 1,
                               force_ipv4 => $target_parameters->{'force_ipv4'},
                               force_ipv6 => $target_parameters->{'force_ipv6'},
                               test_parameters => $target_parameters,
                             };
            }
        }
        unless ($target_parameters->{'receive_only'}) {
            if (is_hostname($target->{'address'}) and $target_parameters->{'test_ipv4_ipv6'} and not $target_parameters->{'force_ipv4'} and not $target_parameters->{'force_ipv6'}) {
                push @tests, { target => $target, sender => 1, force_ipv4 => 1, test_parameters => $target_parameters };
                push @tests, { target => $target, sender => 1, force_ipv6 => 1, test_parameters => $target_parameters };
            }
            else {
                push @tests, {
                               target => $target,
                               sender => 1,
                               force_ipv4 => $target_parameters->{'force_ipv4'},
                               force_ipv6 => $target_parameters->{'force_ipv6'},
                               test_parameters => $target_parameters,
                             };
            }
        }
    }

    return @tests;
}

sub _get_target_parameters {
    my ($self, $target, $test_parameters) = @_;
    
    #copy parameters so don't overwrite
    my $merged_parameters = from_json(to_json($test_parameters));
    if ($target->{'override_parameters'}) {
        foreach my $param_key(keys %{$target->{'override_parameters'}}){
            next if($param_key eq 'type');
            $merged_parameters->{$param_key} = $target->{'override_parameters'}->{$param_key};
        }
    }

    return $merged_parameters;
}

__PACKAGE__->meta->make_immutable;

1;
