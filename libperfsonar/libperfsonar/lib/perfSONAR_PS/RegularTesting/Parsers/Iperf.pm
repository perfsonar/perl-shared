package perfSONAR_PS::RegularTesting::Parsers::Iperf;

use strict;
use warnings;

our $VERSION = 3.1;

=head1 NAME

perfSONAR_PS::RegularTesting::Parsers::Iperf;

=head1 DESCRIPTION

A module that provides simple functions for parsing iperf output

=head1 API

=cut

use base 'Exporter';
use Params::Validate qw(:all);
use IO::Socket::SSL;
use URI::Split qw(uri_split);
use HTTP::Response;
use Log::Log4perl qw(get_logger);

our @EXPORT_OK = qw( parse_iperf_output );

my $logger = get_logger(__PACKAGE__);

use perfSONAR_PS::RegularTesting::Results::ThroughputTest;
use perfSONAR_PS::RegularTesting::Results::Endpoint;

=head2 parse_iperf_output()

=cut

sub parse_iperf_output {
    my $parameters = validate( @_, { stdout  => 1, });
    my $stdout  = $parameters->{stdout};

    my %sess_summ = ();

    my ($source_addr, $destination_addr);
    my ($error);

    my ($prev_si, $in_summary);

    for my $line (split('\n', $stdout)) {
        my ( $id, $si, $ei, $txfr, $bw, $jitter, $nlost, $nsent );

        ( $jitter, $nlost, $nsent ) = ( undef, undef, undef );

        # ignore bogus sessions
        if ( $line =~ m#\(nan\%\)# ) {    #"nan" displayed for number
            $error = "Found NaN result";
            last;
        }

        if ( $line =~ m#read failed: Connection refused# ) {
            $error = "Connection refused";
            last;
        }

  
        my ($dest_ip, $dest_port, $src_ip, $src_port);

        if ( ($dest_ip, $dest_port, $src_ip, $src_port) = ($line =~ m#local ([^ ]+) port (\d+) connected with ([^ ]+) port (\d+)#) ) {
            $destination_addr = $dest_ip;
            $source_addr = $src_ip;
        }

        if (   ( ( $id, $si, $ei, $txfr, $bw, $jitter, $nlost, $nsent ) = ($line =~ m#\[\s*(\d+|SUM)\s*\]\s+([0-9\.]+)\s*\-\s*([0-9\.]+)\s+sec\s+(\d+)\s+Bytes\s+(\d+)\s+bits/sec\s+([0-9\.]+)\s+ms\s+(\d+)/\s*(\d+)\s+# ))
            || ( ( $id, $si, $ei, $txfr, $bw ) = ($line =~ m#\[\s*(\d+|SUM)\s*\]\s+([0-9\.]+)\s*\-\s*([0-9\.]+)\s+sec\s+(\d+)\s+Bytes\s+(\d+)\s+bits/sec# ) ) )
        {

            #if (defined $prev_si and $si < $prev_si) {
            if ($ei - $si > 5) {  # Cheesy heuristic...
                $in_summary = 1;
            }

            my $summary_key;
            if ($in_summary) {
                $summary_key = "summary";
            }
            else {
                $summary_key = $si."_".$ei;
            }

            push @{ $sess_summ{$summary_key} }, [ $id, $si, $ei, $bw, $jitter, $nlost, $nsent ];

            $prev_si = $si;
        }
    }

    # validation checks for data - throw out nonsense data
    if ( ( keys %sess_summ ) <= 0 ) {
        $error = "No results";
    }

    # Fill in the intervals
    my $summary_interval;
    my @intervals = ();

    foreach my $interval_range (sort keys %sess_summ) {
        my %interval = ();

        my $summary_session;

        my @streams = ();

        foreach my $summary (@{ $sess_summ{$interval_range} }) {
            if ($summary->[0] eq "SUM") {
                $summary_session = $summary;
                next;
            }

            push @streams, {
                stream_id => $summary->[0],
                start => $summary->[1],
                end   => $summary->[2],
                throughput => $summary->[3],
                jitter => $summary->[4],
                packets_lost => $summary->[5],
                packets_sent => $summary->[6],
            };
        }

        if (not $summary_session and scalar(@{ $sess_summ{$interval_range} }) == 1) {
            $summary_session = $sess_summ{$interval_range}->[0];
        }

        my $interval = {
            streams => \@streams,
            summary => {
                start => $summary_session->[1],
                end   => $summary_session->[2],
                throughput => $summary_session->[3],
                jitter => $summary_session->[4],
                packets_lost => $summary_session->[5],
                packets_sent => $summary_session->[6],
            }
        };

        if ($interval_range eq "summary") {
            $summary_interval = $interval;
        }
        else {
            push @intervals, $interval;
        }
    }

    @intervals = sort{ $a->{summary}->{start} <=> $b->{summary}->{start} } @intervals;

    unless ($summary_interval) {
        my %streams = ();
        my %overall_summary = (
            throughput   => 0,
            jitter       => 0,
            packets_lost => 0,
            packets_sent => 0,
            total_intervals => 0,
        );

        foreach my $interval (@intervals) {
            foreach my $stream (@{ $interval->{streams} }) {
                unless ($streams{$stream->{stream_id}}) {
                    $streams{$stream->{stream_id}} = {
                        stream_id    => $stream->{stream_id},
                        throughput   => 0,
                        jitter       => 0,
                        packets_lost => 0,
                        packets_sent => 0,
                        total_intervals => 0,
                    };
                }

                my $stream_summary = $streams{$stream->{stream_id}};

                $stream_summary->{throughput} += $stream->{throughput};
                $stream_summary->{jitter} += $stream->{jitter} if $stream->{jitter};
                $stream_summary->{packets_lost} += $stream->{packets_lost} if $stream->{packets_lost};
                $stream_summary->{packets_sent} += $stream->{packets_sent} if $stream->{packets_sent};
                $stream_summary->{total_intervals} += 1;
            }

            $overall_summary{throughput} += $interval->{summary}->{throughput};
            $overall_summary{jitter} += $interval->{summary}->{jitter} if $interval->{summary}->{jitter};
            $overall_summary{packets_lost} += $interval->{summary}->{packets_lost} if $interval->{summary}->{packets_lost};
            $overall_summary{packets_sent} += $interval->{summary}->{packets_sent} if $interval->{summary}->{packets_sent};
            $overall_summary{total_intervals} += 1;
        }

        foreach my $stream_id (keys %streams) {
            my $stream = $streams{$stream_id};
            
            $stream->{throughput} /= $stream->{total_intervals};
            $stream->{jitter} /= $stream->{total_intervals};
            delete($stream->{total_intervals});
        }

        if ($overall_summary{total_intervals}) {
            $overall_summary{throughput} /= $overall_summary{total_intervals};
            $overall_summary{jitter} /= $overall_summary{total_intervals};
        }

        delete($overall_summary{total_intervals});

        my @streams = values %streams;

        $summary_interval = {
            streams => \@streams,
            summary => {
                throughput => $overall_summary{throughput},
                jitter => $overall_summary{jitter},
                packets_sent => $overall_summary{packets_sent},
                packets_lost => $overall_summary{packets_lost},
            }
        };
    }

    return {
        source => $source_addr,
        destination => $destination_addr,
        error => $error,
        intervals => \@intervals,
        summary => $summary_interval,
    };
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
