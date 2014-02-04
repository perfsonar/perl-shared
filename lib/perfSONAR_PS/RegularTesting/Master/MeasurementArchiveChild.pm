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

my $logger = get_logger(__PACKAGE__);

override 'child_main_loop' => sub {
    my ($self) = @_;

    $0 .= ": Measurement Archive: ".$self->measurement_archive->nonce;

    while (1) {
        my $job = $self->active_queue->wait_for_queued_job();
        my $results = $job->get_data();

        $logger->debug("Got queued job");

        my ($status, $res) = $self->handle_results($results);
        if ($status != 0) {
            # XXX: We need to figure out how to handle the failed results. Only
            # periodicially retry?
            $self->failed_queue->enqueue_string($results);
        }

        $job->finish();
    }

    return;
};

sub handle_results {
    my ($self, $results) = @_;

    my $parsed = JSON->new->utf8(1)->decode($results);

    my $object = perfSONAR_PS::RegularTesting::Results::Base->parse($parsed);

    my ($status, $res) = $self->measurement_archive->store_results(results => $object);
    if ($status != 0) {
        my $msg = "Problem storing results: ".$res;
        $logger->error($msg);
        return ($status, $msg);
    }

    return (0, "");
}

1;
