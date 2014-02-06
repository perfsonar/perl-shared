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
    my ($sess_id, $min_si, $max_ei);

    my ($source_addr, $destination_addr);
    my ($error);
    my ($throughput, $jitter, $packets_sent, $packets_lost);


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

        if (   ( ( $id, $si, $ei, $txfr, $bw, $jitter, $nlost, $nsent ) = ($line =~ m#\[\s*(\d+)\s*\]\s+([0-9\.]+)\s*\-\s*([0-9\.]+)\s+sec\s+(\d+)\s+Bytes\s+(\d+)\s+bits/sec\s+([0-9\.]+)\s+ms\s+(\d+)/(\d+)\s+# ))
            || ( ( $id, $si, $ei, $txfr, $bw ) = ($line =~ m#\[\s*(\d+)\s*\]\s+([0-9\.]+)\s*\-\s*([0-9\.]+)\s+sec\s+(\d+)\s+Bytes\s+(\d+)\s+bits/sec# ) ) )
        {
            $sess_id = $id if ( !defined( $sess_id ) );
            next if ( $id != $sess_id );

            if ( !defined( $min_si ) ) {
                $min_si = $si;
            }
            else {
                $min_si = $si if ( $si < $min_si );
            }

            if ( !defined( $max_ei ) ) {
                $max_ei = $ei;
            }
            else {
                $max_ei = $ei if ( $ei > $max_ei );
            }
            @{ $sess_summ{"${si}_${ei}"} } = ( $si, $ei, $bw, $jitter, $nlost, $nsent );
        }
    }

    # validation checks for data - throw out nonsense data
    if ( ( keys %sess_summ ) <= 0 ) {
        $error = "No results";
    }
    elsif ( !exists( $sess_summ{"${min_si}_${max_ei}"} ) ) {
        # Average the interval summaries to create an overall summary
        my ($summary_bw, $summary_jitter, $summary_nlost, $summary_nsent) = (0, 0, 0, 0);

        foreach my $summary_key (keys %sess_summ) {
            my $summary = $sess_summ{$summary_key};

            $summary_bw += $summary->[2];
            $summary_jitter += $summary->[3];
            $summary_nlost += $summary->[4];
            $summary_nsent += $summary->[5];
        }
        $summary_jitter = $summary_jitter / (keys %sess_summ);
        $summary_bw     = $summary_bw     / (keys %sess_summ);

        $throughput = $summary_bw;
        $jitter = $summary_jitter;
        $packets_sent = $summary_nsent;
        $packets_lost = $summary_nlost;
    }
    else {
        $throughput = $sess_summ{"${min_si}_${max_ei}"}->[2];
        $jitter = $sess_summ{"${min_si}_${max_ei}"}->[3];
        $packets_lost = $sess_summ{"${min_si}_${max_ei}"}->[4];
        $packets_sent = $sess_summ{"${min_si}_${max_ei}"}->[5];
    }

    return {
        source => $source_addr,
        destination => $destination_addr,
        error => $error,
        throughput => $throughput,
        jitter => $jitter,
        packets_sent => $packets_sent,
        packets_lost => $packets_lost,
    };
}

1;

__END__

=head1 SEE ALSO

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS subversion repository is located at:

  http://anonsvn.internet2.edu/svn/perfSONAR-PS/trunk

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
