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

use Moose;

extends 'perfSONAR_PS::RegularTesting::Tests::Base';

# Common to all bwctl-ish commands
has 'force_ipv4'  => (is => 'rw', isa => 'Bool');
has 'force_ipv6'  => (is => 'rw', isa => 'Bool');
has 'send_only'   => (is => 'rw', isa => 'Bool');
has 'receive_only'=> (is => 'rw', isa => 'Bool');

has '_individual_tests' => (is => 'rw', isa => 'ArrayRef[HashRef]');

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
        unless ($test->parameters->send_only) {
            push @tests, { source => $test->local_address, destination => $target };
        }
        unless ($test->parameters->receive_only) {
            push @tests, { source => $target, destination => $test->local_address };
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

sub run_individual_test {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         test            => 1,
                                         individual_test => 1,
                                         handle_results  => 1,
                                      });
    my $test              = $parameters->{test};
    my $individual_test   = $parameters->{individual_test};
    my $handle_results    = $parameters->{handle_results};

    my ($bwctl_process, $exiting);

    # Kill off the bwctl process we spawn if we get a SIGTERM
    $SIG{TERM} = $SIG{KILL} = sub {
        eval { $bwctl_process->kill_kill() } if ($bwctl_process);
        $exiting = 1;
    };

    my $last_start_time;

    my %handled = ();
    while (1) {
        my $last_start_time = time;

        eval {
            last if $exiting;

            my @cmd = $self->build_cmd({ 
                                         source => $individual_test->{source},
                                         destination => $individual_test->{destination},
                                         results_directory => $individual_test->{results_directory},
                                         schedule => $test->schedule
                                      });

            my ($out, $err);

            $bwctl_process = start \@cmd, \undef, \$out, \$err;
            unless ($bwctl_process) {
                die("Problem running command: $?");
            }

            while (1) {
                last if $exiting;

                pump $bwctl_process;

                $logger->debug("IPC::Run::pump returned: out: ".$out." err: ".$err);

                $err = "";

                my @files = split('\n', $out);
                foreach my $file (@files) {
                    ($file) = ($file =~ /(.*)/); # untaint the silly filename

                    next if $handled{$file};

                    $logger->debug("bwctl output: $file");

                    open(FILE, $file) or next;
                    my $contents = do { local $/ = <FILE> };
                    close(FILE);

                    my $results = $self->build_results({
                            source => $individual_test->{source},
                            destination => $individual_test->{destination},
                            schedule => $test->schedule,
                            output => $contents,
                    });

                    next unless $results;

                    eval {
                        $handle_results->(results => $results);
                    };
                    if ($@) {
                        $logger->error("Problem saving results: $@");
                        next;
                    }

                    unlink($file);

                    $handled{$file} = 1;
                }
            }

            last if $exiting;
        };

        if ($@) {
            $logger->error("Problem running tests: $@");
            if ($bwctl_process) {
                eval {
                    $bwctl_process->kill_kill() 
                };
            }
        }

        last if $exiting;

        my $sleep_time;

        while(($sleep_time = ($last_start_time + 300) - time) > 0) {
            last if $exiting;

            sleep($sleep_time);
        }
    }

    return;
}

override 'run_test' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         test           => 1,
                                         handle_results => 1,
                                      });
    my $test              = $parameters->{test};
    my $handle_results    = $parameters->{handle_results};

    my %children = ();

    foreach my $individual_test (@{ $self->_individual_tests }) {
        my $pid = fork();

        if ($pid < 0) {
            $logger->error("Problem running tests: $@");
            $self->stop_test();
            return;
        }

        if ($pid == 0) {
            $self->run_individual_test({ individual_test => $individual_test, test => $test, handle_results => $handle_results });
            exit(0);
        }

        $individual_test->{pid} = $pid;

        $children{$pid} = $individual_test;
    }

    while(my $pid = waitpid(-1, 0) > 0) { }

    return;
};

override 'stop_test' => sub {
    my ($self) = @_;

    my %exited = ();

    foreach my $test (@{ $self->_individual_tests }) {
        if ($test->{pid}) {
            kill('TERM', $test->{pid});
        }
    }

    # Wait for the children to exit
    sleep(1);

    # Reap any children that exited
    my $pid;
    do {
        $pid = waitpid(-1, WNOHANG);
        $exited{$pid} = 1 if $pid > 0;
    } while $pid > 0;

    # Kill any remaining children more ... powerfully
    foreach my $test (@{ $self->_individual_tests }) {
        if ($test->{pid} and not $exited{$test->{pid}}) {
            kill('KILL', $test->{pid});
        }
    }

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

    # Reap any remaining children before we exit
    do {
        $pid = waitpid(-1, WNOHANG);
    } while $pid > 0;
};

sub build_cmd {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         source => 1,
                                         destination => 1,
                                         results_directory => 1,
                                         schedule => 0,
                                      });
    my $source            = $parameters->{source};
    my $destination       = $parameters->{destination};
    my $results_directory = $parameters->{results_directory};
    my $schedule          = $parameters->{schedule};

    my @cmd = ();
    push @cmd, ( '-s', $source ) if $source;
    push @cmd, ( '-c', $destination ) if $destination;
    push @cmd, ( '-T', $self->tool ) if $self->tool;
    push @cmd, '-4' if $self->force_ipv4;
    push @cmd, '-6' if $self->force_ipv6;

    # Add the scheduling information
    push @cmd, ( '-I', $schedule->interval );
    push @cmd, ( '-p', '-d', $results_directory );

    return @cmd;
}

sub build_results {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         source => 1,
                                         destination => 1,
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
