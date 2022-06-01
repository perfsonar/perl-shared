package perfSONAR_PS::RegularTesting::Tests::Bwctl2Base;

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

extends 'perfSONAR_PS::RegularTesting::Tests::BwctlBase';

my $logger = get_logger(__PACKAGE__);

override 'valid_schedule' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         schedule => 0,
                                      });
    my $schedule = $parameters->{schedule};

    return 1 if ($schedule->type eq "regular_intervals");

    return 0 if ($schedule->type eq "time_schedule");

    return 1 if ($schedule->type eq "streaming");

    return;
};

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

override 'stop_test' => sub {
    my ($self) = @_;

    $self->_runner->stop();
};

override 'handle_output' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { test => 1, individual_test => 1, stdout => 0, stderr => 0, handle_results => 1 });
    my $test            = $parameters->{test};
    my $individual_test = $parameters->{individual_test};
    my $stdout          = $parameters->{stdout};
    my $stderr          = $parameters->{stderr};
    my $handle_results  = $parameters->{handle_results};

    foreach my $line (@$stdout) {
        ($line) = ($line =~ /(.*)/); # untaint the silly line
        next unless $line;

        my $results = $self->build_results({
                source => $individual_test->{source},
                destination => $individual_test->{destination},
                test_parameters => $individual_test->{test_parameters},
                schedule => $test->schedule,
                output => $line,
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
};

override 'build_cmd' => sub {
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
    #elsif ($schedule->type eq "time_schedule") {
    #    my $schedule_str = join(",", @{ $schedule->time_slots });
    #    push @cmd, ( '--schedule', $schedule_str );
    #}
    #push @cmd, ( '-L', $test_parameters->latest_time ) if $test_parameters->latest_time;

    #push @cmd, ( '--flip' ) if $test_parameters->local_firewall and $local_destination;

    if ($test_parameters->can("packet_tos_bits") and $test_parameters->packet_tos_bits) {
        push @cmd, ( '--tos', $test_parameters->packet_tos_bits );
    }
    
    # Have the tool use the most parsable format
    push @cmd, ( '--parsable' );
    
    return @cmd;
};

1;
