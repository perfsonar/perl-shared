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
has 'window_size'   => (is => 'rw', isa => 'Int');

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "bwctl" };

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
    my $results_directory = $parameters->{results_directory};
    my $test_parameters   = $parameters->{test_parameters};
    my $schedule          = $parameters->{schedule};

    my @cmd = ();
    push @cmd, $test_parameters->bwctl_cmd;

    # Add the parameters from the parent class
    push @cmd, super();

    push @cmd, '-u' if $test_parameters->use_udp;
    push @cmd, ( '-P', $test_parameters->streams ) if $test_parameters->streams;
    push @cmd, ( '-t', $test_parameters->duration ) if $test_parameters->duration;
    push @cmd, ( '-b', $test_parameters->udp_bandwidth ) if $test_parameters->udp_bandwidth;
    push @cmd, ( '-O', $test_parameters->omit_interval ) if $test_parameters->omit_interval;
    push @cmd, ( '-l', $test_parameters->buffer_length ) if $test_parameters->buffer_length;
    push @cmd, ( '-w', $test_parameters->window_size ) if $test_parameters->window_size;

    # Set a default reporting interval
    push @cmd, ( '-i', '1' );

    # Have the tool use the most parsable format
    push @cmd, ( '--parsable' );

    return @cmd;
};

override 'build_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         source => 1,
                                         destination => 1,
                                         test_parameters => 0,
                                         schedule => 0,
                                         output => 1,
                                      });
    my $source          = $parameters->{source};
    my $destination     = $parameters->{destination};
    my $test_parameters = $parameters->{test_parameters};
    my $schedule        = $parameters->{schedule};
    my $output          = $parameters->{output};

    my $results = perfSONAR_PS::RegularTesting::Results::ThroughputTest->new();

    my $protocol;
    if ($test_parameters->use_udp) {
        $protocol = "udp";
    }
    else {
        $protocol = "tcp";
    }

    # Fill in the information we know about the test
    $results->source($self->build_endpoint(address => $source, protocol => $protocol));
    $results->destination($self->build_endpoint(address => $destination, protocol => $protocol));

    $results->protocol($protocol);
    $results->streams($test_parameters->streams);
    $results->time_duration($test_parameters->duration);
    $results->bandwidth_limit($test_parameters->udp_bandwidth) if $test_parameters->udp_bandwidth;
    $results->buffer_length($test_parameters->buffer_length) if $test_parameters->buffer_length;

    # Add in the raw output
    $results->raw_results($output);

    # Parse the bwctl output, and add it in
    my $bwctl_results = parse_bwctl_output({ stdout => $output });

    # Fill in the data that came directly from BWCTL itself
    $results->source->address($bwctl_results->{sender_address}) if $bwctl_results->{sender_address};
    $results->destination->address($bwctl_results->{receiver_address}) if $bwctl_results->{receiver_address};
    $results->tool($bwctl_results->{tool});
    
    push @{ $results->errors }, $bwctl_results->{error} if ($bwctl_results->{error});

    $results->start_time($bwctl_results->{start_time});
    $results->end_time($bwctl_results->{end_time});

    # Fill in the data that came from the tool itself
    if ($bwctl_results->{tool} eq "iperf") {
        $test_parameters->fill_iperf_data({ results_obj => $results, results => $bwctl_results->{results} });
    }
    elsif ($bwctl_results->{tool} eq "iperf3") {
        $test_parameters->fill_iperf3_data({ results_obj => $results, results => $bwctl_results->{results} });
    }
    else {
        push @{ $results->errors }, "Unknown tool type: ".$bwctl_results->{tool};
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

    my $is_reverse = $results->{start}->{test_start}->{reverse};

    # Creating a mapping to map the streams from the client and the server.
    my %stream_map = ();
    if ($results->{start}->{connected} and
        $results->{server_output_json}->{start}->{connected}) {
        foreach my $client_stream (@{ $results->{start}->{connected} }) {
            my $client_stream_id = $client_stream->{socket};

            foreach my $server_stream (@{ $results->{server_output_json}->{start}->{connected} }) {
                my $server_stream_id = $server_stream->{socket};

                next unless ($client_stream->{local_port} eq $server_stream->{remote_port});

                $stream_map{$client_stream_id} = $server_stream_id;
            }
        }
    }

    # Map the server side and client side intervals
    my @json_intervals = ();
    if ($results->{intervals}) {
        foreach my $client_interval (@{ $results->{intervals} }) {
            my $interval_info = {
                client_side => $client_interval,
            };

	    # Find the server side interval that, time-wise, matches the client
	    # side interval
            my $client_start = int($client_interval->{sum}->{start});
            my $client_end   = int($client_interval->{sum}->{end});

            if ($results->{server_output_json}->{intervals}) {
                foreach my $server_interval (@{ $results->{server_output_json}->{intervals} }) {
                    my $server_start = int($server_interval->{sum}->{start});
                    my $server_end   = int($server_interval->{sum}->{end});

                    next unless ($server_start == $client_start and $server_end == $client_end);

                    $interval_info->{server_side} = $server_interval;

                    last;
                }
            }

            push @json_intervals, $interval_info;
        }
    }

    $logger->debug("iperf3 output: ".Dumper($results));

    # Build the intervals
    my @intervals = ();
    foreach my $interval_info (@json_intervals) {
        my $client_interval = $interval_info->{client_side};
        my $server_interval = $interval_info->{server_side};

        my $interval_obj = perfSONAR_PS::RegularTesting::Results::ThroughputTestInterval->new();

        $interval_obj->start($client_interval->{sum}->{start});
        $interval_obj->duration($client_interval->{sum}->{seconds});

        my @streams = ();
        foreach my $client_stream (@{ $client_interval->{streams} }) {
            my $stream_obj = perfSONAR_PS::RegularTesting::Results::ThroughputTestResults->new();

	    # Try to map the client side and server side streams into the
	    # sending and receiving sides of this stream.
            my ($sender_stream, $receiver_stream);

            my $server_stream_id = $stream_map{$client_stream->{socket}};
            if ($server_stream_id and $server_interval) {
                foreach my $server_stream (@{ $server_interval->{streams} }) {
                    next unless ($server_stream->{socket} == $server_stream_id);

                    if ($is_reverse) {
                        $receiver_stream = $client_stream;
                        $sender_stream = $server_stream;
                    }
                    else {
                        $receiver_stream = $server_stream;
                        $sender_stream = $client_stream;
                    }

                    last;
                }
            }

	    # We couldn't find a server-side stream to match to this one for
	    # some reason, so we have to use the client side stats.
            unless ($sender_stream and $receiver_stream) {
                $sender_stream   = $client_stream;
                $receiver_stream = $client_stream;
            }

            $stream_obj->stream_id($sender_stream->{socket}."->".$receiver_stream->{socket});
            $stream_obj->throughput($receiver_stream->{bits_per_second});
            $stream_obj->retransmits($sender_stream->{retransmits});
            $stream_obj->snd_cwnd($sender_stream->{snd_cwnd});
            $stream_obj->jitter($receiver_stream->{jitter_ms});
            $stream_obj->packets_lost($receiver_stream->{lost_packets});
            $stream_obj->packets_sent($receiver_stream->{packets});
            push @streams, $stream_obj;
        }

        $interval_obj->streams(\@streams);

        # Try to map the client side and server side streams into the
        # sending and receiving sides of this stream.
        my ($sender_summary, $receiver_summary);
        if ($server_interval) {
            if ($is_reverse) {
                $sender_summary = $server_interval->{sum};
                $receiver_summary = $client_interval->{sum};
            }
            else {
                $sender_summary = $client_interval->{sum};
                $receiver_summary = $server_interval->{sum};
            }
        }

        # We couldn't find a server-side stream to match to this one for
        # some reason, so we have to use the client side stats.
        unless ($sender_summary and $receiver_summary) {
            $sender_summary   = $client_interval->{sum};
            $receiver_summary = $client_interval->{sum};
        }

        my $summary_results = perfSONAR_PS::RegularTesting::Results::ThroughputTestResults->new();
        $summary_results->throughput($receiver_summary->{bits_per_second});
        $summary_results->jitter($receiver_summary->{jitter_ms});
        $summary_results->retransmits($sender_summary->{retransmits});
        $summary_results->snd_cwnd($sender_summary->{snd_cwnd});
        $summary_results->packets_lost($receiver_summary->{lost_packets});
        $summary_results->packets_sent($receiver_summary->{packets});

        $interval_obj->summary_results($summary_results);

        push @intervals, $interval_obj;
    }

    # Build the summary results
    my $summary_result_obj = perfSONAR_PS::RegularTesting::Results::ThroughputTestInterval->new();

    my @streams = ();
    foreach my $stream (@{ $results->{end}->{streams} }) {
        my ($sender_stream, $receiver_stream);

        if ($stream->{receiver}) {
            $sender_stream = $stream->{sender};
            $receiver_stream = $stream->{receiver};
        }
        else {
            $sender_stream = $stream->{udp};
            $receiver_stream = $stream->{udp};
        }

        my $stream_obj = perfSONAR_PS::RegularTesting::Results::ThroughputTestResults->new();
        $stream_obj->stream_id($receiver_stream->{socket});
        $stream_obj->throughput($receiver_stream->{bits_per_second});
        $stream_obj->retransmits($sender_stream->{retransmits});
        $stream_obj->snd_cwnd($sender_stream->{snd_cwnd});
        $stream_obj->jitter($receiver_stream->{jitter_ms});
        $stream_obj->packets_lost($receiver_stream->{lost_packets});
        $stream_obj->packets_sent($receiver_stream->{packets});
        push @streams, $stream_obj;
    }

    $summary_result_obj->streams(\@streams);

    my ($received_summary, $sent_summary);
    if ($results->{end}->{sum_received}) {
        $received_summary = $results->{end}->{sum_received};
        $sent_summary     = $results->{end}->{sum_sent};
    }

    unless ($received_summary and $sent_summary) {
        $received_summary = $results->{end}->{sum};
        $sent_summary     = $results->{end}->{sum};
    }

    my $summary_overall_obj = perfSONAR_PS::RegularTesting::Results::ThroughputTestResults->new();

    if ($received_summary and $sent_summary) {
        $summary_overall_obj->throughput($received_summary->{bits_per_second}) if $received_summary->{bits_per_second};
        $summary_overall_obj->jitter($received_summary->{jitter_ms}) if $received_summary->{jitter_ms};
        $summary_overall_obj->packets_sent($received_summary->{packets}) if defined $received_summary->{packets};
        $summary_overall_obj->packets_lost($received_summary->{lost_packets}) if defined $received_summary->{lost_packets};
        $summary_overall_obj->retransmits($sent_summary->{retransmits}) if defined $sent_summary->{retransmits};
        $summary_overall_obj->snd_cwnd($sent_summary->{snd_cwnd}) if defined $sent_summary->{snd_cwnd};
    }
    
    $summary_result_obj->summary_results($summary_overall_obj);

    # Fill in the test
    $results_obj->intervals(\@intervals);
    $results_obj->summary_results($summary_result_obj);
    push @{ $results_obj->errors }, $results->{error} if ($results->{error});

    return;
}

1;
