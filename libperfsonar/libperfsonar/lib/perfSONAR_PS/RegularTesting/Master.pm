package perfSONAR_PS::RegularTesting::Master;

use strict;
use warnings;

our $VERSION = 3.5.1;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use Time::HiRes;
use File::Spec;
use File::Path;
use POSIX;
use JSON;

use perfSONAR_PS::RegularTesting::DirQueue;

use perfSONAR_PS::RegularTesting::Config;
use perfSONAR_PS::RegularTesting::Master::SelfScheduledTestChild;
use perfSONAR_PS::RegularTesting::Master::MeasurementArchiveChild;

use Moose;

has 'config'        => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Config');
has 'exiting'       => (is => 'rw', isa => 'Bool');
has 'children'      => (is => 'rw', isa => 'HashRef', default => sub { {} } );

has 'ma_queues'     => (is => 'rw', isa => 'ArrayRef', default => sub { [] } );

my $logger = get_logger(__PACKAGE__);

sub init {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         config => 1,
                                      });
    my $config = $parameters->{config};

    eval {
        my $parsed_config = perfSONAR_PS::RegularTesting::Config->parse($config, 1);
        $self->config($parsed_config);
    };
    if ($@) {
        die("Problem parsing configuration file: $@");
    }

    $self->exiting(0);

    # Initialize the queue directories for these measurement_archives
    my @measurement_archives = @{ $self->config->measurement_archives };
    foreach my $test (@{ $self->config->tests }) {
        next if $test->disabled;

        push @measurement_archives, @{ $test->measurement_archives} if $test->measurement_archives;
    }

    foreach my $measurement_archive (@measurement_archives) {
        my $queue_directory = $measurement_archive->queue_directory;

        unless ($queue_directory) {
            $queue_directory = File::Spec->catdir($self->config->test_result_directory, $measurement_archive->nonce);
        }

        my $active_directory = File::Spec->catdir($queue_directory, "active");
        my $failed_directory = File::Spec->catdir($queue_directory, "failed");

        foreach my $directory ($active_directory, $failed_directory) {
            $logger->debug("Creating directory: $directory");
            my $directory_errors;
            mkpath($directory, { error => \$directory_errors, mode => 0770, verbose => 0 });
            if ($directory_errors and scalar(@$directory_errors) > 0) {
                die("Problem creating ".$directory);
            }
        }

        my $active_queue = perfSONAR_PS::RegularTesting::DirQueue->new({ fan_out => 1, dir => $active_directory });
        my $failed_queue = perfSONAR_PS::RegularTesting::DirQueue->new({ fan_out => 1, dir => $failed_directory });

        $self->add_ma_queues({ measurement_archive => $measurement_archive, active_queue => $active_queue, failed_queue => $failed_queue });
    }

    # Initialize the tests before spawning processes
    foreach my $test (@{ $self->config->tests }) {
        next if $test->disabled;

        $test->init_test(config => $self->config);
    }

    $SIG{CHLD} = sub {
        $self->handle_child_exit();
    };

    $SIG{TERM} = $SIG{INT} = sub {
        $self->handle_exit();
    };

    return;
}

sub get_ma_queues {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { measurement_archive => 1 });
    my $measurement_archive = $parameters->{measurement_archive};
    my $queue               = $parameters->{queue};

    foreach my $ma_queue (@{ $self->ma_queues }) {
        return $ma_queue if ($ma_queue->{measurement_archive} eq $measurement_archive);
    }

    return;
}

sub add_ma_queues {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { measurement_archive => 1, active_queue => 1, failed_queue => 1 });
    my $measurement_archive = $parameters->{measurement_archive};
    my $active_queue        = $parameters->{active_queue};
    my $failed_queue        = $parameters->{failed_queue};

    return if $self->get_ma_queues({ measurement_archive => $measurement_archive });

    push @{ $self->ma_queues }, { measurement_archive => $measurement_archive, active_queue => $active_queue, failed_queue => $failed_queue };

    return;
}

sub run {
    my ($self) = @_;

    $0 = "perfSONAR Regular Testing";

    my @measurement_archives = @{ $self->config->measurement_archives };
    foreach my $test (@{ $self->config->tests }) {
        push @measurement_archives, @{ $test->measurement_archives} if $test->measurement_archives;
    }

    foreach my $measurement_archive (@measurement_archives) {
        $logger->debug("Spawning measurement archive handler: ".$measurement_archive->nonce);

        my $ma_queues = $self->get_ma_queues({ measurement_archive => $measurement_archive });

        my $child = perfSONAR_PS::RegularTesting::Master::MeasurementArchiveChild->new();
        $child->measurement_archive($measurement_archive);
        $child->config($self->config);
        $child->active_queue($ma_queues->{active_queue});
        $child->failed_queue($ma_queues->{failed_queue});

        my $pid = $child->run();
        $self->children->{$pid} = $child;
    }

    foreach my $test (@{ $self->config->tests }) {
        if ($test->disabled) {
            $logger->debug("Skipping disabled test: ".$test->description);
            next;
        }

        $logger->debug("Spawning test: ".$test->description);

        my @mas = ();

        if ($test->measurement_archives) {
            @mas = @{ $test->measurement_archives };
        }
        else {
            @mas = @{ $self->config->measurement_archives };
        }

        my @ma_queues = ();
        foreach my $ma (@mas) {
            my $ma_queues = $self->get_ma_queues({ measurement_archive => $ma });

            push @ma_queues, { ma => $ma, queue => $ma_queues->{active_queue} };
        }

        my $child = perfSONAR_PS::RegularTesting::Master::SelfScheduledTestChild->new();

        $child->test($test);
        $child->config($self->config);
        $child->ma_queues(\@ma_queues);

        my $pid = $child->run();
        $self->children->{$pid} = $child;
    }

    # Sleep waiting to handle various signals
    while (1) {
       sleep(-1);
    }

    return;
}

sub handle_child_exit {
    my ($self) = @_;

    while( ( my $pid = waitpid( -1, &WNOHANG ) ) > 0 ) {
        $logger->debug("Received SIGCHLD for PID: ".$pid);
        my $child = $self->children->{$pid};
        if (not $child) {
            $logger->debug("Received SIGCHLD for unknown PID: ".$pid);
            next;
        }

        delete($self->children->{$pid});

        unless ($self->exiting) {
            $logger->debug("Child exited. Restarting...");

            if ($child->can("test")) {
                $logger->debug("Spawning child: ".$child->test->description);
            }
            elsif ($child->can("measurement_archive")) {
                $logger->debug("Spawning child: ".$child->measurement_archive->nonce);
            }

            my $pid = $child->run();
            $self->children->{$pid} = $child;
        }
    }

    return;
}

sub handle_exit {
    my ($self) = @_;

    $self->exiting(1);

    if (scalar(keys %{ $self->children }) > 0) {
        foreach my $pid (keys %{ $self->children }) {
            my $child = $self->children->{$pid};

	    # Make sure the child while we were looping through this.
            next unless $child;

            $child->kill_child();
        }

        # Wait three seconds for processes to exit
        my $waketime = time + 3;
        while ((my $sleep_time = $waketime - time) > 0 and 
               scalar keys %{ $self->children } > 0) {
            sleep($sleep_time);
        }

        foreach my $pid (keys %{ $self->children }) {
            my $child = $self->children->{$pid};

	    # Make sure the child while we were looping through this.
            next unless $child;

            $logger->debug("Child $pid hasn't exited. Sending SIGKILL");
            $child->kill_child({ force => 1 });
        }
    }

    $logger->debug("Process '".$0."' exiting");

    exit(0);
}

sub exec_command {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         cmd => 1,
                                      });
    my $cmd = $parameters->{cmd};

}

1;
