package perfSONAR_PS::RegularTesting::Parsers::Bwctl;

use strict;
use warnings;

our $VERSION = 3.1;

=head1 NAME

perfSONAR_PS::RegularTesting::Parsers::Bwctl;

=head1 DESCRIPTION

A module that provides simple functions for parsing bwctl output.

=head1 API

=cut

use base 'Exporter';
use Data::Dumper;
use Params::Validate qw(:all);
use IO::Socket::SSL;
use URI::Split qw(uri_split);
use HTTP::Response;
use Log::Log4perl qw(get_logger);

use perfSONAR_PS::RegularTesting::Parsers::Iperf      qw(parse_iperf_output);
use perfSONAR_PS::RegularTesting::Parsers::Iperf3     qw(parse_iperf3_output);
use perfSONAR_PS::RegularTesting::Parsers::Owamp      qw(parse_owamp_raw_output);
use perfSONAR_PS::RegularTesting::Parsers::Ping       qw(parse_ping_output);
use perfSONAR_PS::RegularTesting::Parsers::Traceroute qw(parse_traceroute_output);
use perfSONAR_PS::RegularTesting::Parsers::Tracepath  qw(parse_tracepath_output);
use perfSONAR_PS::RegularTesting::Parsers::ParisTraceroute  qw(parse_paristraceroute_output);

use perfSONAR_PS::RegularTesting::Utils qw(owptstampi2datetime);

our @EXPORT_OK = qw( parse_bwctl_output fill_iperf_data fill_iperf3_data);

my $logger = get_logger(__PACKAGE__);

use DateTime;

=head2 parse_bwctl_output()

=cut

sub parse_bwctl_output {
    my $parameters = validate( @_, { stdout  => 1,
                                     stderr  => 0,
                                     tool    => 0,
                                   });
    my $stdout    = $parameters->{stdout};
    my $stderr    = $parameters->{stderr};
    my $tool      = $parameters->{tool};

    my $output_without_bwctl = "";

    my %results = ();
    for my $line (split('\n', $stdout)) {
        my $time;
        if (($time) = $line =~ /bwctl: start_endpoint: ([0-9.]+)/) {
            $results{start_time} = owptstampi2datetime($time);
        }
        elsif (($time) = $line =~ /bwctl: stop_endpoint: ([0-9.]+)/) {
            $results{end_time} = owptstampi2datetime($time) unless $results{end_time};
        }
        elsif (($time) = $line =~ /bwctl: start_tool: ([0-9.]+)/) {
            $results{start_time} = owptstampi2datetime($time);
        }
        elsif (($time) = $line =~ /bwctl: stop_exec: ([0-9.]+)/) {
            $results{end_time} = owptstampi2datetime($time);
        }
        elsif (($time) = $line =~ /bwctl: stop_tool: ([0-9.]+)/) {
            $results{end_time} = owptstampi2datetime($time);
        }
        elsif (($time) = $line =~ /bwctl: run_tool: receiver: (.*)/) {
            $results{receiver_address} = $1;
        }
        elsif (($time) = $line =~ /bwctl: run_tool: sender: (.*)/) {
            $results{sender_address} = $1;
        }
        elsif (($time) = $line =~ /bwctl: run_endpoint: receiver: (.*)/) {
            $results{receiver_address} = $1;
        }
        elsif (($time) = $line =~ /bwctl: run_endpoint: sender: (.*)/) {
            $results{sender_address} = $1;
        }
        # Special-case some of the tool handling in case something happens
        # before exec can write the tester out.
        elsif ($line =~ /bwctl: exec_line: owping/) {
            $results{tool} = "owamp";
        }
        elsif ($line =~ /bwctl: exec_line: traceroute/) {
            $results{tool} = "traceroute";
        }
        elsif ($line =~ /bwctl: exec_line: tracepath/) {
            $results{tool} = "tracepath";
        }
        elsif ($line =~ /bwctl: exec_line: paris-traceroute/) {
            $results{tool} = "paris-traceroute";
        }
        elsif ($line =~ /bwctl: exec_line: iperf/) {
            $results{tool} = "iperf";
        }
        elsif ($line =~ /bwctl: exec_line: nuttcp/) {
            $results{tool} = "nuttcp";
        }
        elsif ($line =~ /bwctl: run_tool: tester: (.*)/) {
            $results{tool} = $1;
        }
        elsif ($line =~ /bwctl: Unable to initiate peer handshake/) {
            $results{error} = $line;
        }
        elsif ($line =~ /bwctl: Unable to connect/) {
            $results{error} = $line;
        }
        elsif ($line =~ /bwctl:/) {
            # XXX: handle other errors
        }
        else {
            $output_without_bwctl .= "\n".$line;
        }
    }

    $tool = $results{tool} unless $tool;

    if (not $tool) {
        unless ($results{error}) {
            $results{error} = "Tool is not defined";
        }
    }
    elsif ($tool eq "iperf") {
        $results{results} = parse_iperf_output({ stdout => $stdout });
    }
    elsif ($tool eq "iperf3") {
        $results{results} = parse_iperf3_output({ stdout => $stdout });
    }
    elsif ($tool eq "traceroute") {
        $results{results} = parse_traceroute_output({ stdout => $output_without_bwctl });
    }
    elsif ($tool eq "tracepath") {
        $results{results} = parse_tracepath_output({ stdout => $output_without_bwctl });
    }
    elsif ($tool eq "paris-traceroute") {
        $results{results} = parse_paristraceroute_output({ stdout => $output_without_bwctl });
    }
    elsif ($tool eq "ping") {
        $results{results} = parse_ping_output({ stdout => $stdout });
    }
    elsif ($tool eq "owamp") {
        $results{results} = parse_owamp_raw_output({ stdout => $stdout });
    }
    else {
        $results{error} = "Unknown tool type: $tool";
    }

    $results{raw_results} = $stdout;

    return \%results;
}

sub fill_iperf_data {
    my (@args) = @_;
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
    my (@args) = @_;
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

__END__

=head1 SEE ALSO

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS git repository is located at:

  https://code.google.com/p/perfsonar-ps/

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id: Host.pm 5139 2012-06-01 15:48:46Z aaron $

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 COPYRIGHT

Copyright (c) 2008-2009, Internet2

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
