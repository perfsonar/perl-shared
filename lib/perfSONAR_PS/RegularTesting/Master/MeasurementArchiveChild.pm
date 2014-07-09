package perfSONAR_PS::RegularTesting::Master::MeasurementArchiveChild;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use JSON;
use POSIX ":sys_wait_h";

use Moose;

extends 'perfSONAR_PS::RegularTesting::Master::BaseChild';

has 'measurement_archive' => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::MeasurementArchives::Base');

has 'max_workers'         => (is => 'rw', isa => 'Int');

has 'workers'             => (is => 'rw', isa => 'HashRef', default => sub { {} });

has 'failed_queue'        => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::DirQueue');
has 'active_queue'        => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::DirQueue');

has 'fail_retry_interval' => (is => 'rw', isa => 'Int', default => 300);

has 'next_retry_failed_time' => (is => 'rw', isa => 'Int', default => 0);

my $logger = get_logger(__PACKAGE__);

override 'child_main_loop' => sub {
    my ($self) = @_;

    $0 .= ": Measurement Archive: ".$self->measurement_archive->nonce;

    if ($self->measurement_archive->supports_parallelism) {
        $self->max_workers($self->measurement_archive->max_parallelism);
    }
    else {
        $self->max_workers(1);
    }

    # The idea here is to maintain 2 queues: an active queue (where new test
    # results are placed), and a failed queue (where test results that couldn't
    # be stored in the MA are stored. We then go through, and grab 1 from each
    # queue (holding off on the failed queue if we've retried recently), and
    # then process them. This ensures that neither active nor failed results
    # starve each other out.
    while (1) {
        my @jobs = ();

        # We grab a reference to the current time here to avoid a bizarre race
        # condition where when we check for whether we should be handling
        # failed reservations, time < $self->next_retry_failed_time, but when we
        # check later for how long to wait, time >= $self->next_retry_failed_time.
        my $curr_time = time;

        # Grab a failed job from the stack if there is one, and we're in "retry
        # failed results mode".
        if ($self->next_retry_failed_time <= $curr_time) {
            my $job = $self->failed_queue->pickup_queued_job();
            push @jobs, $job if $job;
        }

        # Try to grab an existing new test result
        my $job = $self->active_queue->pickup_queued_job();
        push @jobs, $job if $job;

        # If we don't have anything to do, wait until we can get a new job.
        # Either a) because we can retry failed jobs, or b) because one came in
        # from the active queue
        if (scalar(@jobs) == 0) {
            my $timeout = $self->next_retry_failed_time - $curr_time;

            # A timeout of 0 in DirQueue means "wait indefinitely."
            if ($timeout < 0) {
                $timeout = 0;
            }

            my $job = $self->active_queue->wait_for_queued_job($timeout);
            push @jobs, $job if $job;
        }

        while (my $job = $self->active_queue->pickup_queued_job()) {
            push @jobs, $job;
        }

        # This can only occur if we get a timeout waiting for when we should be
        # retrying failed jobs
        next if (scalar(@jobs) == 0);

        # Go through each of the jobs (at most 2), and try to add them. In the
        # case of a failure condition, the assumption is that it was a failure
        # that will apply to all tests, so we'll hold off on retrying failed
        # tests until later.
        foreach my $job (@jobs) {
            while (scalar(keys %{ $self->workers }) > $self->max_workers) {
                my $child_pid = waitpid(-1, 0);
                my $child_status = $?;

                if ($child_pid > 0) {
                    $self->handle_worker_exit({ pid => $child_pid, status => $child_status });
                }
            }

            my $results = $job->get_data();

            $logger->debug("Got queued job");

            my $pid = fork();
            if ($pid == 0) {
                my ($status, $res);

                eval {
                    local $SIG{ALRM} = sub { die("Timeout") };

                    # allow it to run for no more than 5 seconds
                    alarm(5);

                    ($status, $res) = $self->handle_results($results);
                    die($res) if ($status != 0);
                };
                if ($@) {
                    $logger->error("Problem handling test results: $@");
                    exit(-1);
                }

                exit(0);
            }

            $self->workers->{$pid} = {
                job => $job,
                results => $results
            };
        }

        # Put in a small pause to keep the daemon from monopolizing the CPU in
        # the situation where there are a large number of failed tests.
        sleep(1);

        while ((my $child_pid = waitpid(-1, WNOHANG)) > 0) {
            my $child_status = $?;

            if ($child_pid > 0) {
                $self->handle_worker_exit({ pid => $child_pid, status => $child_status });
            }
        }
    }

    return;
};

override 'child_initialize_signals' => sub {
    super();

    $SIG{CHLD} = 'DEFAULT';
};

sub handle_worker_exit {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { pid => 1, status => 1 } );
    my $pid = $parameters->{pid};
    my $status = $parameters->{status};

    if ($self->workers->{$pid}) {
        my $results = $self->workers->{$pid}->{results};
        my $job     = $self->workers->{$pid}->{job};

        delete($self->workers->{$pid});

        if ($status != 0) {
            $self->failed_queue->enqueue_string($results);
            $self->next_retry_failed_time(time + $self->fail_retry_interval);
        }

        $job->finish();

    }
}

sub handle_results {
    my ($self, $results) = @_;

    my $parsed = JSON->new->utf8(1)->decode($results);

    unless ($parsed->{results} and $parsed->{test} and $parsed->{target} and $parsed->{test_parameters}) {
        my $msg = "Problem parsing results";
        $logger->error($msg);
        return (-1, $msg);
    }

    my ($test_obj, $target_obj, $parameters_obj, $results_obj);
    eval {
        $test_obj    = perfSONAR_PS::RegularTesting::Test->parse($parsed->{test});
        $results_obj = perfSONAR_PS::RegularTesting::Results::Base->parse($parsed->{results});
        $target_obj  = perfSONAR_PS::RegularTesting::Target->parse($parsed->{target});
        $parameters_obj  = perfSONAR_PS::RegularTesting::Tests::Base->parse($parsed->{test_parameters});
    };
    if ($@) {
        my $msg = "Problem parsing results: $@";
        $logger->error($msg);
        return (-1, $msg);
    }

    my ($status, $res) = $self->measurement_archive->store_results(test => $test_obj, target => $target_obj, test_parameters => $parameters_obj, results => $results_obj);
    if ($status != 0) {
        my $msg = "Problem storing results: ".$res;
        $logger->error($msg);
        return ($status, $msg);
    }

    return (0, "");
}

1;
