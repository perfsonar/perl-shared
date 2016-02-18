package perfSONAR_PS::RegularTesting::Tests::BwctlBase;

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

use perfSONAR_PS::RegularTesting::Results::Endpoint;

use perfSONAR_PS::RegularTesting::Utils::CmdRunner;
use perfSONAR_PS::RegularTesting::Utils::CmdRunner::Cmd;

use Moose;

extends 'perfSONAR_PS::RegularTesting::Tests::Base';

# Common to all bwctl-ish commands
has 'force_ipv4'      => (is => 'rw', isa => 'Bool');
has 'force_ipv6'      => (is => 'rw', isa => 'Bool');
has 'test_ipv4_ipv6'  => (is => 'rw', isa => 'Bool');
has 'send_only'       => (is => 'rw', isa => 'Bool');
has 'receive_only'    => (is => 'rw', isa => 'Bool');
has 'latest_time'     => (is => 'rw', isa => 'Int');
has 'local_firewall'  => (is => 'rw', isa => 'Bool');
has 'control_address' => (is => 'rw', isa => 'Str');

has '_individual_tests' => (is => 'rw', isa => 'ArrayRef[HashRef]');
has '_runner'           => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Utils::CmdRunner');

my $logger = get_logger(__PACKAGE__);

override 'allows_bidirectional' => sub { 1 };

override 'handles_own_scheduling' => sub { 1; };

override 'valid_schedule' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         schedule => 0,
                                      });
    my $schedule = $parameters->{schedule};

    return 1 if ($schedule->type eq "regular_intervals");

    return 1 if ($schedule->type eq "time_schedule");

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

	# If they specify an interface, use that. If they specify an address,
	# that takes precendence.
        my $local_address;
        $local_address = $test->local_interface if $test->local_interface;
        $local_address = $test->local_address   if $test->local_address;

        unless ($target_parameters->receive_only) {
            if (is_hostname($target->address) and $target_parameters->test_ipv4_ipv6 and not $target_parameters->force_ipv4 and not $target_parameters->force_ipv6) {
                push @tests, { target => $target, local_destination => 0, source => $local_address, destination => $target->address, force_ipv4 => 1, test_parameters => $target_parameters };
                push @tests, { target => $target, local_destination => 0, source => $local_address, destination => $target->address, force_ipv6 => 1, test_parameters => $target_parameters };
            }
            else {
                push @tests, {
                               target      => $target,
                               source      => $local_address,
                               destination => $target->address,
                               force_ipv4 => $target_parameters->force_ipv4,
                               force_ipv6 => $target_parameters->force_ipv6,
                               test_parameters => $target_parameters,
                               local_destination => 0,
                             };

            }
        }
        unless ($target_parameters->send_only) {
            if (is_hostname($target->address) and $target_parameters->test_ipv4_ipv6 and not $target_parameters->force_ipv4 and not $target_parameters->force_ipv6) {
                push @tests, { target => $target, local_destination => 1, source => $target->address, destination => $local_address, force_ipv4 => 1, test_parameters => $target_parameters };
                push @tests, { target => $target, local_destination => 1, source => $target->address, destination => $local_address, force_ipv6 => 1, test_parameters => $target_parameters };
            }
            else {
                push @tests, {
                               target => $target,
                               source => $target->address,
                               destination => $local_address,
                               force_ipv4 => $target_parameters->force_ipv4,
                               force_ipv6 => $target_parameters->force_ipv6,
                               test_parameters => $target_parameters,
                               local_destination => 1,
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
            $test->{results_directory} = tempdir($config->test_result_directory."/bwctl_XXXXX");
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
        my @cmd = $self->build_cmd({ 
                                     source => $individual_test->{source},
                                     destination => $individual_test->{destination},
                                     local_destination => $individual_test->{local_destination},
                                     force_ipv4 => $individual_test->{force_ipv4},
                                     force_ipv6 => $individual_test->{force_ipv6},
                                     results_directory => $individual_test->{results_directory},
                                     test_parameters => $individual_test->{test_parameters},
                                     schedule => $test->schedule
                                  });

        my $cmd = perfSONAR_PS::RegularTesting::Utils::CmdRunner::Cmd->new();
        $cmd->cmd(\@cmd);
        $cmd->private($individual_test);
        $cmd->restart_interval(300);
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
               $logger->error("Couldn't remove: ".$test->{results_directory});
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

    foreach my $file (@$stdout) {
        ($file) = ($file =~ /(.*)/); # untaint the silly filename

        my $contents;

        if (open(FILE, $file)) {
            $contents = do { local $/ = <FILE> };
            close(FILE);
        }

        unlink($file);

        next unless $contents;

        my $results = $self->build_results({
                source => $individual_test->{source},
                destination => $individual_test->{destination},
                test_parameters => $individual_test->{test_parameters},
                schedule => $test->schedule,
                output => $contents,
        });

        next unless $results;

        eval {
            $handle_results->(test => $test, target => $individual_test->{target}, test_parameters => $individual_test->{test_parameters}, results => $results);
        };
        if ($@) {
            $logger->error("Problem saving results: $@");
        }
    }

    return;
}

sub build_cmd {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         source => 1,
                                         destination => 1,
                                         local_destination => 1,
                                         force_ipv4 => 0,
                                         force_ipv6 => 0,
                                         results_directory => 1,
                                         test_parameters => 1,
                                         schedule => 0,
                                      });
    my $source            = $parameters->{source};
    my $destination       = $parameters->{destination};
    my $local_destination = $parameters->{local_destination};
    my $force_ipv4        = $parameters->{force_ipv4};
    my $force_ipv6        = $parameters->{force_ipv6};
    my $results_directory = $parameters->{results_directory};
    my $test_parameters   = $parameters->{test_parameters};
    my $schedule          = $parameters->{schedule};

    my @cmd = ();
    push @cmd, ( '-s', $source ) if $source;
    push @cmd, ( '-c', $destination ) if $destination;
    push @cmd, ( '-T', $test_parameters->tool ) if $test_parameters->tool;
    
    # Always set -B to ensure that control packets are not 
    # unintentionally redirected by host routing tables
    if($test_parameters->control_address){
        push @cmd, ( '-B', $test_parameters->control_address ) ;
    }elsif($parameters->{local_destination}){
        push @cmd, ( '-B', $destination ) if($destination);
    }elsif($source){
        push @cmd, ( '-B', $source ) ;
    }
    
    push @cmd, '-4' if $force_ipv4;
    push @cmd, '-6' if $force_ipv6;

    # Add the scheduling information
    if ($schedule->type eq "streaming") {
        push @cmd, ( '--streaming' );
    }
    elsif ($schedule->type eq "regular_intervals") {
        push @cmd, ( '-I', $schedule->interval );
        push @cmd, ( '-R', $schedule->random_start_percentage ) if(defined $schedule->random_start_percentage);
    }
    elsif ($schedule->type eq "time_schedule") {
        my $schedule_str = join(",", @{ $schedule->time_slots });
        push @cmd, ( '--schedule', $schedule_str );
    }
    push @cmd, ( '-p', '-d', $results_directory );
    push @cmd, ( '-L', $test_parameters->latest_time ) if $test_parameters->latest_time;

    push @cmd, ( '--flip' ) if $test_parameters->local_firewall and $local_destination;

    if ($test_parameters->can("packet_tos_bits") and $test_parameters->packet_tos_bits) {
        push @cmd, ( '--tos', $test_parameters->packet_tos_bits );
    }

    # Make sure verbose mode is on
    push @cmd, ( '-v' );

    return @cmd;
}

sub build_results {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         source => 1,
                                         destination => 1,
                                         test_parameters => 1,
                                         schedule => 0,
                                         output => 1,
                                      });

    die("'build_results' should be overridden");
}

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

1;
