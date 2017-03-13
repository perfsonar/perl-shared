package perfSONAR_PS::RegularTesting::Tests::Powstream;

use strict;
use warnings;

our $VERSION = 3.4;

use IPC::Run qw( start pump );
use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use File::Temp qw(tempdir);
use File::Path qw(rmtree);

use POSIX ":sys_wait_h";

use Data::Validate::IP qw(is_ipv4);
use Data::Validate::Domain qw(is_hostname);
use Net::IP;

use perfSONAR_PS::RegularTesting::Utils::CmdRunner;
use perfSONAR_PS::RegularTesting::Utils::CmdRunner::Cmd;

use perfSONAR_PS::RegularTesting::Utils qw(owptime2datetime choose_endpoint_address parse_target);
use perfSONAR_PS::Utils::DNS qw(discover_source_address);
use perfSONAR_PS::Utils::Host qw(get_interface_addresses_by_type);

use perfSONAR_PS::RegularTesting::Parsers::Owamp qw(parse_owamp_summary_file);
use perfSONAR_PS::RegularTesting::Results::LatencyTest;
use perfSONAR_PS::RegularTesting::Results::LatencyTestDatum;

use Moose;

extends 'perfSONAR_PS::RegularTesting::Tests::Base';

has 'powstream_cmd'     => (is => 'rw', isa => 'Str', default => '/usr/bin/powstream');
has 'owstats_cmd'       => (is => 'rw', isa => 'Str', default => '/usr/bin/owstats');
has 'send_only'         => (is => 'rw', isa => 'Bool');
has 'receive_only'      => (is => 'rw', isa => 'Bool');
has 'force_ipv4'        => (is => 'rw', isa => 'Bool');
has 'force_ipv6'        => (is => 'rw', isa => 'Bool');
has 'test_ipv4_ipv6'    => (is => 'rw', isa => 'Bool');
has 'resolution'        => (is => 'rw', isa => 'Int', default => 60);
has 'packet_length'     => (is => 'rw', isa => 'Int', default => 0);
has 'inter_packet_time' => (is => 'rw', isa => 'Num', default => 0.1);
has 'receive_port_range' => (is => 'rw', isa => 'Str');
has 'log_level'          => (is => 'rw', isa => 'Str');
has 'output_raw'        => (is => 'rw', isa => 'Bool');
has 'packet_tos_bits'   => (is => 'rw', isa => 'Int');
   
has '_individual_tests' => (is => 'rw', isa => 'ArrayRef[HashRef]');
has '_runner'           => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Utils::CmdRunner');

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "powstream" };

override 'allows_bidirectional' => sub { 1 };

override 'handles_own_scheduling' => sub { 1; };

override 'valid_schedule' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         schedule => 0,
                                      });
    my $schedule = $parameters->{schedule};

    return 1 if ($schedule->type eq "streaming");

    return;
};

sub get_individual_tests {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         test => 1,
                                      });
    my $test              = $parameters->{test};

    my @tests = ();
 
    # Build the set of set of tests that make up this bwctl test
    foreach my $target (@{ $test->targets }) {
        my $target_parameters = $test->get_target_parameters(target => $target);

        unless ($target_parameters->send_only) {
            if (is_hostname($target->address) and $target_parameters->test_ipv4_ipv6 and not $target_parameters->force_ipv4 and not $target_parameters->force_ipv6) {
                push @tests, { target => $target, receiver => 1, force_ipv4 => 1, test_parameters => $target_parameters };
                push @tests, { target => $target, receiver => 1, force_ipv6 => 1, test_parameters => $target_parameters };
            }
            else {
                push @tests, {
                               target => $target,
                               receiver => 1,
                               force_ipv4 => $target_parameters->force_ipv4,
                               force_ipv6 => $target_parameters->force_ipv6,
                               test_parameters => $target_parameters,
                             };
            }
        }
        unless ($target_parameters->receive_only) {
            if (is_hostname($target->address) and $target_parameters->test_ipv4_ipv6 and not $target_parameters->force_ipv4 and not $target_parameters->force_ipv6) {
                push @tests, { target => $target, sender => 1, force_ipv4 => 1, test_parameters => $target_parameters };
                push @tests, { target => $target, sender => 1, force_ipv6 => 1, test_parameters => $target_parameters };
            }
            else {
                push @tests, {
                               target => $target,
                               sender => 1,
                               force_ipv4 => $target_parameters->force_ipv4,
                               force_ipv6 => $target_parameters->force_ipv6,
                               test_parameters => $target_parameters,
                             };
            }
        }
    }

    return @tests;
}

override 'init_test' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         test   => 1,
                                         config => 1,
                                      });
    my $test   = $parameters->{test};
    my $config = $parameters->{config};

    my @individual_tests = $self->get_individual_tests({ test => $test });

    foreach my $test (@individual_tests) {
        eval {
            $test->{results_directory} = tempdir($config->test_result_directory."/owamp_XXXXX");
        };
        if ($@) {
            die("Couldn't create directory to store results: ".$@);
        }
    }

    $self->_individual_tests(\@individual_tests);

    return;
};

override 'run_test' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         test           => 1,
                                         handle_results => 1,
                                      });
    my $test              = $parameters->{test};
    my $handle_results    = $parameters->{handle_results};

    my @cmds = ();
    foreach my $individual_test (@{ $self->_individual_tests }) {
        my $test_parameters = $individual_test->{test_parameters};

        # Calculate the total number of packets from the resolution
        my $packets = $test_parameters->resolution / $test_parameters->inter_packet_time;

        my @cmd = ();
        push @cmd, $test_parameters->powstream_cmd;
        push @cmd, '-4' if $individual_test->{force_ipv4};
        push @cmd, '-6' if $individual_test->{force_ipv6};
        push @cmd, ( '-p', '-d', $individual_test->{results_directory} );
        push @cmd, ( '-c', $packets );
        push @cmd, ( '-s', $test_parameters->packet_length ) if $test_parameters->packet_length;
        push @cmd, ( '-i', $test_parameters->inter_packet_time ) if $test_parameters->inter_packet_time;
        push @cmd, ( '-P', $test_parameters->receive_port_range ) if $test_parameters->receive_port_range;
        push @cmd, ( '-g', $test_parameters->log_level ) if $test_parameters->log_level;
        
        if ($test->local_address) {
            push @cmd, ( '-S', $test->local_address );
        }
        elsif ($test->local_interface) {
            push @cmd, ( '-S', $test->local_interface );
        }
        push @cmd, '-t' if $individual_test->{sender};
        push @cmd, $individual_test->{target}->address;

        my $cmd = perfSONAR_PS::RegularTesting::Utils::CmdRunner::Cmd->new();

        $cmd->cmd(\@cmd);
        $cmd->private($individual_test);
        $cmd->restart_interval(300);
        $cmd->result_timeout($test_parameters->resolution * 3); #restart process if no result in three times the resolution time
        $cmd->result_cb(sub {
            my ($cmd, @args) = @_;
            my $parameters = validate( @args, { stdout => 0, stderr => 0 });
            my $stdout = $parameters->{stdout};
            my $stderr = $parameters->{stderr};

            $self->handle_output({ test => $test, individual_test => $individual_test, stdout => $stdout, stderr => $stderr, handle_results => $handle_results });
        });

        push @cmds, $cmd;
    }

    $self->_runner(perfSONAR_PS::RegularTesting::Utils::CmdRunner->new());
    $self->_runner->init({ cmds => \@cmds });
    $self->_runner->run();

    return;
};

override 'stop_test' => sub {
    my ($self) = @_;

    $self->_runner->stop();

    # Remove the directories we created
    foreach my $test (@{ $self->_individual_tests }) {
        if (-d $test->{results_directory}) {
           eval {
               rmtree($test->{results_directory});
           };
           if ($@) {
               $logger->error("Couldn't remove: ".$test->{results_directory}.": ".$@);
           }
           else {
               $logger->debug("Removed: ".$test->{results_directory});
           }
        }
    }
};

sub handle_output {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { test => 1, individual_test => 1, stdout => 0, stderr => 0, handle_results => 1 });
    my $test            = $parameters->{test};
    my $individual_test = $parameters->{individual_test};
    my $stdout          = $parameters->{stdout};
    my $stderr          = $parameters->{stderr};
    my $handle_results  = $parameters->{handle_results};

    if ($stderr and scalar(@$stderr) > 0) {
        $logger->debug("Powstream output: ".join('\n', @$stderr));
    }

    foreach my $file (@$stdout) {
        ($file) = ($file =~ /(.*)/); # untaint the silly filename

        chomp($file);

        $logger->debug("Received file: $file");

        unless ($file =~ /(.*).(sum)$/) {
            unlink($file);
            next;
        }

        my $source = $individual_test->{sender}?$test->local_address:$individual_test->{target}->address;
        my $destination = $individual_test->{receiver}?$test->local_address:$individual_test->{target}->address;


        my $results = $self->build_results({
                                             source => $source,
                                             destination => $destination,
                                             test_parameters => $individual_test->{test_parameters},
                                             schedule => $test->schedule,
                                             summary_file => $file,
                                          });
        unless ($results) {
            $logger->error("Problem parsing test results");
            next;
        }
        else {
            eval {
                $handle_results->(test => $test, target => $individual_test->{target}, test_parameters => $individual_test->{test_parameters}, results => $results);
            };
            if ($@) {
                $logger->error("Problem saving results: $@");
            }
        }

        unlink($file);
    }

    return;
}

sub build_results {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         source => 1,
                                         destination => 1,
                                         test_parameters => 1,
                                         schedule => 0,
                                         summary_file => 1,
                                      });
    my $source          = $parameters->{source};
    my $destination     = $parameters->{destination};
    my $test_parameters = $parameters->{test_parameters};
    my $schedule        = $parameters->{schedule};
    my $summary_file    = $parameters->{summary_file};

    my $summary         = parse_owamp_summary_file({ summary_file => $summary_file });

    unless ($summary) {
        $logger->error("Problem parsing test results");
        return;
    }

    use Data::Dumper;
    #$logger->debug("Raw output: ".Dumper($raw));
    $logger->debug("Summary output: ".Dumper($summary));

    my $results = perfSONAR_PS::RegularTesting::Results::LatencyTest->new();

    # Fill in the information we know about the test
    $results->source($self->build_endpoint(address => $source, protocol => "udp" ));
    $results->destination($self->build_endpoint(address => $destination, protocol => "udp" ));

    $results->packet_count($test_parameters->resolution/$test_parameters->inter_packet_time);
    $results->packet_size($test_parameters->packet_length);
    $results->inter_packet_time($test_parameters->inter_packet_time);

    my $from_addr = $summary->{FROM_ADDR};
    my $to_addr = $summary->{TO_ADDR};

    $from_addr =~ s/%.*//;
    $to_addr =~ s/%.*//;

    $results->source->address($from_addr) if $from_addr;
    $results->destination->address($to_addr) if $to_addr;
    $results->start_time(owptime2datetime($summary->{START_TIME}));
    $results->end_time(owptime2datetime($summary->{END_TIME}));


    # Add the summarized results since adding the raw results is absurdly
    # expensive for powstream tests...
    $results->packets_sent($summary->{SENT});
    $results->packets_received($summary->{SENT} - $summary->{LOST});
    $results->duplicate_packets($summary->{DUPS});
    $results->time_error_estimate($summary->{MAXERR});
    
    $results->histogram_bucket_size($summary->{BUCKET_WIDTH});

    my %delays = ();
    foreach my $bucket (keys %{ $summary->{BUCKETS} }) {
        # make the bucket milliseconds
        $delays{$bucket * $summary->{BUCKET_WIDTH} * 1000.0} = $summary->{BUCKETS}->{$bucket};
    }
    $results->delay_histogram(\%delays);

    my %ttls = ();
    %ttls = %{ $summary->{TTLBUCKETS} } if $summary->{TTLBUCKETS};
    $results->ttl_histogram(\%ttls);

    $results->raw_results("");

    # XXX: look into error conditions

    # XXX: I'm guessing the raw results should be the owp? I'm dunno
    $results->raw_results("");

    use Data::Dumper;
    $logger->debug("Results: ".Dumper($results->unparse));

    return $results;
};

sub build_endpoint {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         address  => 1,
                                         port     => 0,
                                         protocol => 0,
                                      });
    my $address        = $parameters->{address};
    my $port           = $parameters->{port};
    my $protocol       = $parameters->{protocol};

    my $endpoint = perfSONAR_PS::RegularTesting::Results::Endpoint->new();

    if ( is_ipv4( $address ) or 
         &Net::IP::ip_is_ipv6( $address ) ) {
        $endpoint->address($address);
    }
    else {
        $endpoint->hostname($address);
    }

    $endpoint->port($port) if $port;
    $endpoint->protocol($protocol) if $protocol;

    return $endpoint;
}

override 'to_pscheduler' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         url => 1,
                                         test => 1,
                                         archive_map => 1,
                                         task_manager => 1,
                                         global_bind_map => 1,
                                         global_lead_bind_map => 1,
                                      });
    my $psc_url = $parameters->{url};
    my $test = $parameters->{test};
    my $archive_map = $parameters->{archive_map};
    my $task_manager = $parameters->{task_manager};
    my $global_bind_map = $parameters->{global_bind_map};
    my $global_lead_bind_map = $parameters->{global_lead_bind_map};
    
    #handle interface definitions, which pscheduler does not support
    my $interface_ips;
    if($test->local_interface && !$test->local_address){
        $interface_ips = get_interface_addresses_by_type(interface => $test->local_interface);
        unless(@{$interface_ips->{ipv4_address}} || @{$interface_ips->{ipv6_address}}){
            die "Unable to determine addresses for interface " . $test->local_interface;
        }
    }
    
    foreach my $individual_test ($self->get_individual_tests({ test => $test })) {
        my $force_ipv4        = $individual_test->{force_ipv4};
        my $force_ipv6        = $individual_test->{force_ipv6};
        my $test_parameters   = $individual_test->{test_parameters};
        my $packets = $test_parameters->resolution / $test_parameters->inter_packet_time;
        my $schedule          = $test->schedule();
        
        #determine local address which is only complicated if interface specified
        my $parsed_target = parse_target(target=>$individual_test->{target}->address());
        my ($local_address, $local_port, $source, $destination, $destination_port);
        if($interface_ips){
            my ($choose_status, $choose_res) = choose_endpoint_address(
                                                        ifname => $test->local_interface,
                                                        interface_ips => $interface_ips, 
                                                        target_address => $parsed_target->{address},
                                                        force_ipv4 => $force_ipv4,
                                                        force_ipv6 => $force_ipv6,
                                                    );
            if($choose_status < 0){
                $logger->error("Error determining local address, skipping test: " . $choose_res);
                next;
            }else{
                $local_address = $choose_res;
            }
        }
        
        #now determine source and destination - again only complicated by interface names
        unless($local_address){
            my $parsed_local = parse_target(target=> $test->local_address);
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
            $destination = $local_address;
            $destination_port = $local_port;
        }else{
            #always set source so we don't end up with 127.0.0.1
            $local_address = discover_source_address(address => $parsed_target->{address}) unless($local_address);
            $source = $local_address;
            $destination = $parsed_target->{address};
            $destination_port = $parsed_target->{port};
        }
        
        #init task
        my $psc_task = new perfSONAR_PS::Client::PScheduler::Task(url => $psc_url);
        $psc_task->reference_param('description', $test->description()) if $test->description();
        foreach my $test_ref(@{$test->references()}){
            next if($test_ref->name() eq 'description' || $test_ref->name() eq 'created-by');
            $psc_task->reference_param($test_ref->name(), $test_ref->value());
        }
        
        #Test parameters
        my $psc_test_spec = {};
        $psc_task->test_type('latencybg');
        $psc_test_spec->{'source'} = $source if($source);
        $psc_test_spec->{'dest'} = $destination if($destination);
        $psc_test_spec->{'ctrl-port'} = int($destination_port) if($destination_port);
        $psc_test_spec->{'flip'} = JSON::true if($individual_test->{receiver});
        $psc_test_spec->{'packet-count'} = int($packets) if $packets;
        $psc_test_spec->{'packet-interval'} = $test_parameters->inter_packet_time + 0.0 if $test_parameters->inter_packet_time;
        $psc_test_spec->{'packet-padding'} = int($test_parameters->packet_length) if defined $test_parameters->packet_length;
        if($test_parameters->receive_port_range()){
            my ($lower, $upper) = split '-', $test_parameters->receive_port_range();
            if($lower && $upper){
                $psc_test_spec->{'data-ports'} = {
                    'lower' => int($lower),
                    'upper' => int($upper),
                };
            }
        }
        $psc_test_spec->{'output-raw'} = JSON::true if($test_parameters->{output_raw});
        $psc_test_spec->{'ip-tos'} = int($test_parameters->packet_tos_bits) if $test_parameters->packet_tos_bits;
        $psc_test_spec->{'ip-version'} = 4 if($force_ipv4);
        $psc_test_spec->{'ip-version'} = 6 if($force_ipv6);
        #set durations so powstream does not run forever
        $psc_test_spec->{'duration'} = 'PT' . $task_manager->new_task_min_ttl() . 'S';
        $psc_task->test_spec($psc_test_spec);
        
        #update binding addresses
        if($individual_test->{target}->bind_address()){
            #prefer binding specified at test level
            $psc_task->add_bind_map($parsed_target->{address}, $individual_test->{target}->bind_address());
        }elsif($test->bind_address()){
            #next check if default bind address at test level
            $psc_task->add_bind_map($parsed_target->{address}, $test->bind_address());
        }elsif(exists $global_bind_map->{$parsed_target->{address}} && $global_bind_map->{$parsed_target->{address}}){
            #fallback to global map where address specified if available
            $psc_task->add_local_bind_map($global_bind_map->{$parsed_target->{address}});
        }elsif(exists $global_bind_map->{'_default'} && $global_bind_map->{'_default'}){
            #fallback to global map default if available
            $psc_task->add_local_bind_map($global_bind_map->{'_default'});
            if($local_address){
                $psc_task->add_bind_map($local_address, $global_bind_map->{'_default'});
            }
        }
        
        
        #update lead binding addresses
        ##Local
        if($individual_test->{target}->local_lead_bind_address()){
            $psc_task->add_local_lead_bind_map($individual_test->{target}->local_lead_bind_address());
            if($local_address){
                $psc_task->add_lead_bind_map($local_address, $individual_test->{target}->local_lead_bind_address());
            }
        }elsif($test->local_lead_bind_address()){
            $psc_task->add_local_lead_bind_map($test->local_lead_bind_address());
            if($local_address){
                $psc_task->add_lead_bind_map($local_address, $test->local_lead_bind_address());
            }
        }elsif(exists $global_lead_bind_map->{$parsed_target->{address}} && $global_lead_bind_map->{$parsed_target->{address}}){
            #fallback to global map where address specified if available
            $psc_task->add_local_lead_bind_map($global_lead_bind_map->{$parsed_target->{address}});
        }elsif(exists $global_lead_bind_map->{'_default'} && $global_lead_bind_map->{'_default'}){
            #fallback to global map default if available
            $psc_task->add_local_lead_bind_map($global_lead_bind_map->{'_default'});
            if($local_address){
                $psc_task->add_lead_bind_map($local_address, $global_lead_bind_map->{'_default'});
            }
        }
        ##Remote
        if($individual_test->{target}->lead_bind_address()){
            $psc_task->add_lead_bind_map($parsed_target->{address}, $individual_test->{target}->lead_bind_address());
        }
        
        #add archives
        my $interval = ($packets ? int($packets) : 600);
        $interval *= ($test_parameters->inter_packet_time ? $test_parameters->inter_packet_time + 0.0 : .1);
        if($archive_map->{'esmond/latency'}){
            foreach my $psc_ma(@{$archive_map->{'esmond/latency'}}){
                $psc_task->add_archive(
                                        $psc_ma->to_pscheduler(
                                                                local_address => $local_address, 
                                                                default_retry_policy => $self->default_retry_policy(interval => $interval) 
                                                              )
                                      );
            }
        }
        if($test->measurement_archives()){
            foreach my $ma(@{$test->measurement_archives()}){
                $psc_task->add_archive(
                                        $ma->to_pscheduler(
                                                            local_address => $local_address,
                                                            default_retry_policy => $self->default_retry_policy(interval => $interval) 
                                                          )
                                      );
            }
        }
        
        $task_manager->add_task(task => $psc_task, local_address => $local_address) if($psc_task);
    }
    
};

1;
