package perfSONAR_PS::RegularTesting::Tests::PSchedulerBase;

use strict;
use warnings;

our $VERSION = 4.0;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use Data::Validate::Domain qw(is_hostname);
use perfSONAR_PS::RegularTesting::Utils qw(choose_endpoint_address parse_target);
use Moose;

extends 'perfSONAR_PS::RegularTesting::Tests::Base';

has 'force_ipv4'      => (is => 'rw', isa => 'Bool');
has 'force_ipv6'      => (is => 'rw', isa => 'Bool');
has 'test_ipv4_ipv6'  => (is => 'rw', isa => 'Bool');
has 'send_only'       => (is => 'rw', isa => 'Bool');
has 'receive_only'    => (is => 'rw', isa => 'Bool');

has '_individual_tests' => (is => 'rw', isa => 'ArrayRef[HashRef]');

my $logger = get_logger(__PACKAGE__);

override 'allows_bidirectional' => sub { 1 };

override 'valid_schedule' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         schedule => 0,
                                      });
    my $schedule = $parameters->{schedule};

    return 1 if ($schedule->type eq "regular_intervals");

    return 1 if ($schedule->type eq "time_schedule");

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
    $self->_individual_tests(\@individual_tests);

    return;
};

sub ma_type {
    #set the type of measurement_archive. kinda a dated concept so just default to throughput
    return 'esmond/throughput';
}

sub psc_test_type {
    my ($self, @args) = @_;
    #override this if you want to use a type different from the pscheduler type
   return $self->type();
}

sub psc_test_spec {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         source => 1,
                                         destination => 1,
                                         local_destination => 1,
                                         force_ipv4 => 0,
                                         force_ipv6 => 0,
                                         test_parameters => 1,
                                         test => 1,
                                      });
    die "Not implemented. Must be overridden by subclass.";
}

override 'to_pscheduler' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         url => 1,
                                         test => 1,
                                         archive_map => 1,
                                         task_manager => 1
                                      });
    my $psc_url = $parameters->{url};
    my $test = $parameters->{test};
    my $archive_map = $parameters->{archive_map};
    my $task_manager = $parameters->{task_manager};
    
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
        $psc_task->test_type($self->psc_test_type());
        $psc_task->test_spec($self->psc_test_spec({ 
                                     source => $source,
                                     destination => $destination,
                                     local_destination => $individual_test->{local_destination},
                                     force_ipv4 => $individual_test->{force_ipv4},
                                     force_ipv6 => $individual_test->{force_ipv6},
                                     test_parameters => $individual_test->{test_parameters},
                                     test => $test
                                  }));
        #schedule parameters
        my $interval;
        if ($schedule->type eq "regular_intervals") {
            if(defined $schedule->interval){
                $interval = $test->schedule()->interval;
                $psc_task->schedule_repeat('PT' . $schedule->interval . 'S');
                #allow a test to be scheduled anytime before the next scheduled run
                $psc_task->schedule_slip('PT' . $schedule->interval . 'S');
            }
            my $randslip = .1;
            $randslip = $schedule->random_start_percentage/100.0 if(defined $schedule->random_start_percentage);
            $psc_task->schedule_randslip($randslip);
        }else{
            $logger->warning("Schedule type " . $schedule->type . " not currently supported. Skipping test.");
            return;
        }
        
        #add archives
        my $ma_type = $self->ma_type();
        if($archive_map->{$ma_type }){
            foreach my $psc_ma(@{$archive_map->{$ma_type }}){
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
