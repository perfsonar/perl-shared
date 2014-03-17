package perfSONAR_PS::RegularTesting::Master::MeasurementArchiveChild;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use JSON;

use Moose;

extends 'perfSONAR_PS::RegularTesting::Master::BaseChild';

has 'measurement_archive' => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::MeasurementArchives::Base');

has 'failed_queue'        => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::DirQueue');
has 'active_queue'        => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::DirQueue');

has 'fail_retry_interval' => (is => 'rw', isa => 'Int', default => 300);

my $logger = get_logger(__PACKAGE__);

override 'child_main_loop' => sub {
    my ($self) = @_;

    $0 .= ": Measurement Archive: ".$self->measurement_archive->nonce;

    my $next_retry_failed_time = 0;

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
        # failed reservations, time < $next_retry_failed_time, but when we
        # check later for how long to wait, time >= $next_retry_failed_time.
        my $curr_time = time;

        # Grab a failed job from the stack if there is one, and we're in "retry
        # failed results mode".
        if ($next_retry_failed_time <= $curr_time) {
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
            my $timeout = $next_retry_failed_time - $curr_time;

            # A timeout of 0 in DirQueue means "wait indefinitely."
            if ($timeout < 0) {
                $timeout = 0;
            }

            my $job = $self->active_queue->wait_for_queued_job($timeout);
            push @jobs, $job if $job;
        }

        # This can only occur if we get a timeout waiting for when we should be
        # retrying failed jobs
        next if (scalar(@jobs) == 0);

        # Go through each of the jobs (at most 2), and try to add them. In the
        # case of a failure condition, the assumption is that it was a failure
        # that will apply to all tests, so we'll hold off on retrying failed
        # tests until later.
        foreach my $job (@jobs) {
            my $results = $job->get_data();

            $logger->debug("Got queued job");

            my ($status, $res);

            eval {
                ($status, $res) = $self->handle_results($results);
            };
            if ($@) {
                $status = -1;
                $res = "Problem handling test results: $@";
            }

            if ($status != 0) {
                $self->failed_queue->enqueue_string($results);
                $next_retry_failed_time = $curr_time + $self->fail_retry_interval;
            }
    
            $job->finish();
        }

        # Put in a small pause to keep the daemon from monopolizing the CPU in
        # the situation where there are a large number of failed tests.
        sleep(1);
    }

    return;
};

sub handle_results {
    my ($self, $results) = @_;

    my $parsed = JSON->new->utf8(1)->decode($results);

    unless ($parsed->{results} and $parsed->{test}) {
        my $msg = "Problem parsing results";
        $logger->error($msg);
        return (-1, $msg);
    }

    my ($test_obj, $results_obj);
    eval {
        $test_obj    = perfSONAR_PS::RegularTesting::Test->parse($parsed->{test});
        $results_obj = perfSONAR_PS::RegularTesting::Results::Base->parse($parsed->{results});
    };
    if ($@) {
        my $msg = "Problem parsing results: $@";
        $logger->error($msg);
        return (-1, $msg);
    }

    my ($status, $res) = $self->measurement_archive->store_results(test => $test_obj, results => $results_obj);
    if ($status != 0) {
        my $msg = "Problem storing results: ".$res;
        $logger->error($msg);
        return ($status, $msg);
    }

    return (0, "");
}

1;
