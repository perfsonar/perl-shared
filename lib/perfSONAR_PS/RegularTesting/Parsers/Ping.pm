package perfSONAR_PS::RegularTesting::Parsers::Ping;

use strict;
use warnings;

our $VERSION = 3.1;

=head1 NAME

perfSONAR_PS::RegularTesting::Parsers::Ping;

=head1 DESCRIPTION

A module that provides simple functions for parsing ping output

=head1 API

=cut

use base 'Exporter';
use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);

our @EXPORT_OK = qw( parse_ping_output );

my $logger = get_logger(__PACKAGE__);

=head2 parse_ping_output()

=cut

sub parse_ping_output {
    my $parameters = validate( @_, { stdout  => 1, });
    my $stdout  = $parameters->{stdout};

    my ($source_addr, $destination_addr);
    my ($sent, $recv);
    my ($minRtt, $maxRtt, $meanRtt);
    my @pings = ();

    for my $line (split('\n', $stdout)) {
        # PING www.slashdot.org (216.34.181.48) from 207.75.165.146 : 56(84) bytes of data.
        # PING nsrc.org(2607:8400:2880:4::80df:9d13) from 2607:8400:2880:4::80df:9d13 : 56 data bytes
        if ($line =~ /PING ([^ ]*) ?\(([^ ]*)\) from ([^ ]*)/) {
            $source_addr = $3;
        }

        # PING www.slashdot.org (216.34.181.48) 56(84) bytes of data.
        # PING nsrc.org(2607:8400:2880:4::80df:9d13) 56 data bytes
        if ($line =~ /PING ([^ ]*) ?\(([^ ]*)\)/) {
            $destination_addr = $2;
        }

        # 64 bytes from 207.75.165.244: icmp_seq=2 ttl=63 time=3.194 ms
        if ($line =~ /(\d+) bytes from (.*): icmp_seq=(\d+) ttl=(\d+) time=([0-9.]*) ms/) {
            my ($bytes, $address, $seq, $ttl, $delay) = ($1, $2, $3, $4, $5);

            push @pings, {
                seq => $seq,
                ttl => $ttl,
                delay => $delay,
            };
        }

        if ($line =~ /(\d+) packets transmitted, (\d+) (?:packets )?received/ ) {
            $sent = $1;
            $recv = $2;
        }

        # rtt min/avg/max/mdev = 7.854/7.854/7.854/0.000 ms
        if ($line =~ /(?:rtt|round-trip) min\/avg\/max\/(?:mdev|stddev) \= (\d+\.\d+)\/(\d+\.\d+)\/(\d+\.\d+)\/\d+\.\d+ ms/ ) {
            $minRtt  = $1;
            $meanRtt = $2;
            $maxRtt  = $3;
        }
    }

    return {
        source => $source_addr,
        destination => $destination_addr,
        sent   => $sent,
        recv   => $recv,
        minRtt => $minRtt,
        maxRtt => $maxRtt,
        meanRtt => $meanRtt,
        pings   => \@pings
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
