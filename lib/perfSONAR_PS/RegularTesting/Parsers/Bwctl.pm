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

use perfSONAR_PS::RegularTesting::Utils qw(owptstampi2datetime);

our @EXPORT_OK = qw( parse_bwctl_output );

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
