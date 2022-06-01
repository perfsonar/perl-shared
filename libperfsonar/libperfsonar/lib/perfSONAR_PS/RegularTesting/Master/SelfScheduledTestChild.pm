package perfSONAR_PS::RegularTesting::Master::SelfScheduledTestChild;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use Time::HiRes;
use POSIX;
use JSON;

use Moose;

extends 'perfSONAR_PS::RegularTesting::Master::BaseChild';

has 'test'              => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Test');

has 'ma_queues'         => (is => 'rw', isa => 'ArrayRef', default => sub { [] } );

has 'last_restart_time' => (is => 'rw', isa => 'Int');

my $logger = get_logger(__PACKAGE__);

override 'child_main_loop' => sub {
    my ($self) = @_;

    $0 .= ": Test: ".$self->test->description;

    while (1) {
        if ($self->last_restart_time) {
            $logger->debug("Restarting test: ".$self->test->description);
        }
        else {
            $logger->debug("Running test: ".$self->test->description);
        }

        my $results;
        eval {
            $self->test->run_test(
                handle_results => sub {
                    my $parameters = validate( @_, { test => 1, target => 1, test_parameters => 1, results => 1 });
                    my $test = $parameters->{test};
                    my $target = $parameters->{target};
                    my $test_parameters = $parameters->{test_parameters};
                    my $results = $parameters->{results};
                    $self->save_results(test => $test, target => $target, test_parameters => $test_parameters, results => $results);
                }
            );
        };
        if ($@) {
            my $error = $@;
            $logger->error("Problem with test: ".$self->test->description.": ".$error);
        };

        last if $self->exiting;

        # XXX: don't hard code 5 minutes in here
        if ($self->last_restart_time) {
            while ((my $sleep_time = $self->last_restart_time + 300 - time) > 0) {
                $logger->debug("Waiting $sleep_time seconds to restart test: ".$self->test->description);
                sleep($sleep_time);

                last if $self->exiting;
            }
        }

        $self->last_restart_time(time);
    }

    $self->test->stop_test();

    return;
};

sub save_results {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { test => 1, target => 1, test_parameters => 1, results => 1 });
    my $test            = $parameters->{test};
    my $target          = $parameters->{target};
    my $test_parameters = $parameters->{test_parameters};
    my $results         = $parameters->{results};

    my $result_info = {
        test       => $test->unparse,
        target     => $target->unparse,
        test_parameters => $test_parameters->unparse,
        results    => $results->unparse,
    };

    my $json = JSON->new->pretty->encode($result_info);

    my $enqueued;

    foreach my $ma_info (@{ $self->ma_queues }) {
        my $measurement_archive = $ma_info->{ma};
        my $queue               = $ma_info->{queue};

        if ($measurement_archive->accepts_results({ test => $test, target => $target, test_parameters => $test_parameters, results => $results })) {
            $logger->debug("Enqueueing job to: ".$measurement_archive->nonce);

            unless ($queue->enqueue_string($json)) {
                $logger->error("Problem saving test results to measurement archive");
            }
            else {
                $logger->debug("Enqueued test results for measurement archive: ".$measurement_archive->nonce);
                $enqueued = 1;
            }
        }
    }

    unless ($enqueued) {
        $logger->error("No measurement archive to save test results to");
    }

    return;
}

before 'handle_exit' => sub {
    my ($self) = @_;

    $logger->debug("Stopping test: ".$self->test->description);
    $self->test->stop_test();
};

1;
