package perfSONAR_PS::RegularTesting::Tests::Bwctl;

use strict;
use warnings;

our $VERSION = 3.4;

use IPC::Run qw( start pump );
use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use File::Temp qw(tempdir);

use perfSONAR_PS::RegularTesting::Parsers::Bwctl qw(parse_bwctl_output);

use Moose;

extends 'perfSONAR_PS::RegularTesting::Tests::BwctlBase';

has 'bwctl_cmd' => (is => 'rw', isa => 'Str', default => '/usr/bin/bwctl');
has 'tool' => (is => 'rw', isa => 'Str', default => 'iperf');
has 'use_udp' => (is => 'rw', isa => 'Bool', default => 0);
has 'streams' => (is => 'rw', isa => 'Int', default => 1);
has 'duration' => (is => 'rw', isa => 'Int', default => 10);
has 'omit_interval' => (is => 'rw', isa => 'Int');
has 'udp_bandwidth' => (is => 'rw', isa => 'Int');
has 'buffer_length' => (is => 'rw', isa => 'Int');
has 'packet_tos_bits' => (is => 'rw', isa => 'Int');

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "bwctl" };

override 'build_cmd' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         source => 1,
                                         destination => 1,
                                         force_ipv4 => 0,
                                         force_ipv6 => 0,
                                         results_directory => 1,
                                         schedule => 0,
                                      });
    my $source            = $parameters->{source};
    my $destination       = $parameters->{destination};
    my $results_directory = $parameters->{results_directory};
    my $schedule          = $parameters->{schedule};

    my @cmd = ();
    push @cmd, $self->bwctl_cmd;

    # Add the parameters from the parent class
    push @cmd, super();

    push @cmd, '-u' if $self->use_udp;
    push @cmd, ( '-P', $self->streams ) if $self->streams;
    push @cmd, ( '-t', $self->duration ) if $self->duration;
    push @cmd, ( '-b', $self->udp_bandwidth ) if $self->udp_bandwidth;
    push @cmd, ( '-O', $self->omit_interval ) if $self->omit_interval;
    push @cmd, ( '-l', $self->buffer_length ) if $self->buffer_length;

    # Set a default reporting interval
    push @cmd, ( '-i', '1' );

    push @cmd, ('-y', 'J') if ($self->tool eq "iperf3");

    return @cmd;
};

override 'build_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         source => 1,
                                         destination => 1,
                                         schedule => 0,
                                         output => 1,
                                      });
    my $source         = $parameters->{source};
    my $destination    = $parameters->{destination};
    my $schedule       = $parameters->{schedule};
    my $output         = $parameters->{output};

    my $results = perfSONAR_PS::RegularTesting::Results::ThroughputTest->new();

    my $protocol;
    if ($self->use_udp) {
        $protocol = "udp";
    }
    else {
        $protocol = "tcp";
    }

    # Fill in the information we know about the test
    $results->source($self->build_endpoint(address => $source, protocol => $protocol));
    $results->destination($self->build_endpoint(address => $destination, protocol => $protocol));

    $results->protocol($protocol);
    $results->streams($self->streams);
    $results->time_duration($self->duration);
    $results->bandwidth_limit($self->udp_bandwidth) if $self->udp_bandwidth;
    $results->buffer_length($self->buffer_length) if $self->buffer_length;

    # Add in the raw output
    $results->raw_results($output);

    # Parse the bwctl output, and add it in
    my $bwctl_results = parse_bwctl_output({ stdout => $output, tool_type => $self->tool });

    # Fill in the data that came directly from BWCTL itself
    $results->source->address($bwctl_results->{sender_address}) if $bwctl_results->{sender_address};
    $results->destination->address($bwctl_results->{receiver_address}) if $bwctl_results->{receiver_address};

    push @{ $results->errors }, $bwctl_results->{error} if ($bwctl_results->{error});

    $results->start_time($bwctl_results->{start_time});
    $results->end_time($bwctl_results->{end_time});

    # Fill in the data that came from the tool itself
    if ($self->tool eq "iperf") {
        $self->fill_iperf_data({ results_obj => $results, results => $bwctl_results->{results} });
    }
    elsif ($self->tool eq "iperf3") {
        $self->fill_iperf3_data({ results_obj => $results, results => $bwctl_results->{results} });
    }
    else {
        push @{ $results->errors }, "Unknown tool type: ".$self->tool;
    }

    use Data::Dumper;
    $logger->debug("Build Results: ".Dumper($results->unparse));

    return $results;
};

sub fill_iperf_data {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         results_obj => 1,
                                         results => 1,
                                      });
    my $results_obj    = $parameters->{results_obj};
    my $results        = $parameters->{results};

    # Build the intervals
    my @intervals = ();
    foreach my $interval (@{ $results->{intervals} }) {
        my $interval_obj = perfSONAR_PS::RegularTesting::Results::ThroughputTestInterval->new();

        $interval_obj->start($interval->{summary}->{start});
        $interval_obj->duration($interval->{summary}->{end} - $interval->{summary}->{start});

        my @streams = ();
        foreach my $stream (@{ $interval->{streams} }) {
            my $stream_obj = perfSONAR_PS::RegularTesting::Results::ThroughputTestResults->new();
            $stream_obj->stream_id($stream->{stream_id});
            $stream_obj->throughput($stream->{throughput});
            $stream_obj->jitter($stream->{jitter});
            $stream_obj->packets_lost($stream->{packets_lost});
            $stream_obj->packets_sent($stream->{packets_sent});
            push @streams, $stream_obj;
        }

        $interval_obj->streams(\@streams);

        my $summary_results = perfSONAR_PS::RegularTesting::Results::ThroughputTestResults->new();
        $summary_results->throughput($interval->{summary}->{throughput});
        $summary_results->jitter($interval->{summary}->{jitter});
        $summary_results->packets_sent($interval->{summary}->{packets_sent});
        $summary_results->packets_lost($interval->{summary}->{packets_lost});

        $interval_obj->summary_results($summary_results);

        push @intervals, $interval_obj;
    }

    # Build the summary results
    my $summary_result_obj = perfSONAR_PS::RegularTesting::Results::ThroughputTestInterval->new();

    my @streams = ();
    foreach my $stream (@{ $results->{summary}->{streams} }) {
        my $stream_obj = perfSONAR_PS::RegularTesting::Results::ThroughputTestResults->new();
        $stream_obj->stream_id($stream->{stream_id});
        $stream_obj->throughput($stream->{throughput});
        $stream_obj->jitter($stream->{jitter});
        $stream_obj->packets_lost($stream->{packets_lost});
        $stream_obj->packets_sent($stream->{packets_sent});
        push @streams, $stream_obj;
    }

    $summary_result_obj->streams(\@streams);

    my $summary_overall_obj = perfSONAR_PS::RegularTesting::Results::ThroughputTestResults->new();
    $summary_overall_obj->throughput($results->{summary}->{summary}->{throughput}) if $results->{summary}->{summary}->{throughput};
    $summary_overall_obj->jitter($results->{summary}->{summary}->{jitter}) if $results->{summary}->{summary}->{jitter};
    $summary_overall_obj->packets_sent($results->{summary}->{summary}->{packets_sent}) if defined $results->{summary}->{summary}->{packets_sent};
    $summary_overall_obj->packets_lost($results->{summary}->{summary}->{packets_lost}) if defined $results->{summary}->{summary}->{packets_lost};

    $summary_result_obj->summary_results($summary_overall_obj);

    # Fill in the test
    $results_obj->intervals(\@intervals);
    $results_obj->summary_results($summary_result_obj);
    push @{ $results_obj->errors }, $results->{error} if ($results->{error});

    return;
}

sub fill_iperf3_data {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         results_obj => 1,
                                         results => 1,
                                      });
    my $results_obj    = $parameters->{results_obj};
    my $results        = $parameters->{results};

    # Don't do anything if there's an error. Who knows what state the results are in...
    if ($results->{error}) {
        push @{ $results_obj->errors }, $results->{error} if ($results->{error});
        return;
    }

    $logger->debug("iperf3 output: ".Dumper($results));

    # Build the intervals
    my @intervals = ();
    foreach my $interval (@{ $results->{intervals} }) {
        my $interval_obj = perfSONAR_PS::RegularTesting::Results::ThroughputTestInterval->new();

        $interval_obj->start($interval->{sum}->{start});
        $interval_obj->duration($interval->{sum}->{seconds});

        my @streams = ();
        foreach my $stream (@{ $interval->{streams} }) {
            my $stream_obj = perfSONAR_PS::RegularTesting::Results::ThroughputTestResults->new();
            $stream_obj->stream_id($stream->{socket});
            $stream_obj->throughput($stream->{bits_per_second});
            # XXX: $stream_obj->jitter($stream->{jitter});
            # XXX: $stream_obj->packets_lost($stream->{packets_lost});
            # XXX: $stream_obj->packets_sent($stream->{packets_sent});
            push @streams, $stream_obj;
        }

        $interval_obj->streams(\@streams);

        my $summary_results = perfSONAR_PS::RegularTesting::Results::ThroughputTestResults->new();
        $summary_results->throughput($interval->{sum}->{bits_per_second});
        # XXX: $summary_results->jitter($interval->{sum}->{jitter});
        # XXX: $summary_results->packets_sent($interval->{sum}->{packets_sent});
        # XXX: $summary_results->packets_lost($interval->{sum}->{packets_lost});

        $interval_obj->summary_results($summary_results);

        push @intervals, $interval_obj;
    }

    # Build the summary results
    my $summary_result_obj = perfSONAR_PS::RegularTesting::Results::ThroughputTestInterval->new();

    my @streams = ();
    foreach my $stream (@{ $results->{end}->{streams} }) {
        my $stream_obj = perfSONAR_PS::RegularTesting::Results::ThroughputTestResults->new();
        $stream_obj->stream_id($stream->{receiver}->{socket});
        $stream_obj->throughput($stream->{receiver}->{bits_per_second});
        # XXX: $stream_obj->jitter($stream->{jitter});
        # XXX: $stream_obj->packets_lost($stream->{packets_lost});
        # XXX: $stream_obj->packets_sent($stream->{packets_sent});
        push @streams, $stream_obj;
    }

    $summary_result_obj->streams(\@streams);

    my $summary_overall_obj = perfSONAR_PS::RegularTesting::Results::ThroughputTestResults->new();
    $summary_overall_obj->throughput($results->{end}->{sum_received}->{throughput}) if $results->{end}->{sum_received}->{throughput};
    $summary_overall_obj->jitter($results->{end}->{sum_received}->{jitter}) if $results->{end}->{sum_received}->{jitter};
    $summary_overall_obj->packets_sent($results->{end}->{sum_received}->{packets_sent}) if defined $results->{end}->{sum_received}->{packets_sent};
    $summary_overall_obj->packets_lost($results->{end}->{sum_received}->{packets_lost}) if defined $results->{end}->{sum_received}->{packets_lost};

    $summary_result_obj->summary_results($summary_overall_obj);

    # Fill in the test
    $results_obj->intervals(\@intervals);
    $results_obj->summary_results($summary_result_obj);
    push @{ $results_obj->errors }, $results->{error} if ($results->{error});

    return;
}

1;
