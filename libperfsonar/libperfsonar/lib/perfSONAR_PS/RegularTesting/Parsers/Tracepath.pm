package perfSONAR_PS::RegularTesting::Parsers::Tracepath;

use strict;
use warnings;

our $VERSION = 3.1;

=head1 NAME

perfSONAR_PS::RegularTesting::Parsers::Tracepath;

=head1 DESCRIPTION

A module that provides simple functions for parsing tracepath output

=head1 API

=cut

use base 'Exporter';
use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);

our @EXPORT_OK = qw( parse_tracepath_output );

my $logger = get_logger(__PACKAGE__);

=head2 parse_tracepath_output()

=cut

sub parse_tracepath_output {
    my $parameters = validate( @_, { stdout  => 1, });
    my $stdout  = $parameters->{stdout};

#[aaron@lab233 ~]$ tracepath -n mit.edu
# 1:  207.75.165.233    0.265ms pmtu 1500
# 1:  207.75.165.193    0.526ms asymm  2 
# 1:  207.75.165.193    0.466ms asymm  2 
# 2:  192.122.200.41    0.326ms asymm  3 
# 3:  198.108.23.12     6.775ms 
# 4:  12.250.16.17      6.282ms asymm  5 
# 5:  12.122.132.138   10.554ms asymm  7 
# 6:  12.122.132.157    8.302ms 
# 7:  no reply
# 8:  205.171.30.62    28.149ms asymm 11 
# 9:  no reply
#10:  no reply
#11:  no reply
#12:  no reply
#13:  no reply
#14:  no reply
#15:  no reply
#16:  no reply

# 1:  sunn-pt1.es.net (198.129.254.58)                       0.076ms pmtu 9000
# 1:  no reply
# 2:  sacrcr5-ip-a-sunncr5.es.net (134.55.40.5)              3.096ms 
# 3:  denvcr5-ip-a-sacrcr5.es.net (134.55.50.202)           24.067ms 
# 4:  kanscr5-ip-a-denvcr5.es.net (134.55.49.58)            34.657ms 
# 5:  chiccr5-ip-a-kanscr5.es.net (134.55.43.81)            45.633ms 
# 6:  starcr5-ip-a-chiccr5.es.net (134.55.42.42)            45.892ms 
# 7:  xe-0-0-2x2060.nw-chi3.mich.net (207.72.112.77)        46.221ms 
# 8:  xe-1-0-0x76.aa3.mich.net (198.108.23.10)              51.289ms asymm  9 
# 9:  mam-45.merit.edu (192.122.200.45)                     52.124ms asymm 10 
#10:  mam-45.merit.edu (192.122.200.45)                     51.556ms pmtu 1500
#10:  desk146.internet2.edu (207.75.165.146)                51.517ms reached
#     Resume: pmtu 1500 hops 10 back 55 

    my ($path_mtu, $forward_hops, $backward_hops);
    my $finished;
    my %hops = ();

    my $prev_mtu;
    my $found_local;

    for my $line (split('\n', $stdout)) {
        # Trim leading/trailing space
        $line =~ s/^\s+|\s+$//g ;

        if ($line =~ /Resume: pmtu (\d+) hops (\d+) back (\d+)/) {
            # Resume: pmtu 1500 hops 10 back 55 
            $path_mtu      = $1;
            $forward_hops  = $2;
            $backward_hops = $3;
        }
        elsif ($line =~ /^([0-9]+)\??:/) {
            #10:  mam-45.merit.edu (192.122.200.45)                     51.556ms pmtu 1500
            my $ttl = $1;
            my $no_reply = $line =~ /no reply/;
            my $reached = $line =~ /reached/; # It's the final hop
            my ($rtt) = $line =~ /([0-9]+\.[0-9]+)ms/;
            my ($mtu) = $line =~ /pmtu ([0-9]+)/;
            my ($asymm) = $line =~ /asymm ([0-9]+)/;

            my ($address, $hostname);

            my @fields = split(' ', $line);

            if (@fields > 2) {
                if ($fields[2] =~ /^\((.*)\)$/) {
                    $address = $1;

                    $hostname = $fields[1] unless $address eq $fields[1];
                }
                else {
                    $address = $fields[1];
                }
            }

            $mtu = $prev_mtu unless $mtu;

            # Save the current MTU for the next iteration
            $prev_mtu = $mtu;

            # Tracepath always seems to have the first TTL correspond to the
            # local host, as well as the next hop router...
            if ($ttl == 1 and not $found_local) {
                $found_local = 1;
                next;
            }

            # Another odd tracepath case where the last hop can have the same TTL
            # as last router for no apparent reason.
            if ($reached and $hops{$ttl}) {
                if ($hops{$ttl}->[0]->{hop} ne $address) {
                    $ttl++;
                }
            }

            # Skip cases that are obviously wrong
            next unless ($no_reply or $address);

            $hops{$ttl} = [] unless $hops{$ttl};

            my $query_num = scalar(@{ $hops{$ttl} }) + 1;

            my %hop_stats = (
                ttl => $ttl,
                queryNum => $query_num,
            );

            if ($no_reply) {
                $hop_stats{error} = "requestTimedOut"; 
            }
            else {
                $hop_stats{hop} = $address;
                $hop_stats{delay} = $rtt;
                $hop_stats{path_mtu} = $mtu;
            }

            push @{ $hops{$ttl} }, \%hop_stats;
        }
    }

    my @hops = ();
    foreach my $ttl (sort { $a <=> $b } keys %hops) {
        push @hops, @{ $hops{$ttl} };
    }

    return {
        hops => \@hops,
        path_mtu => $path_mtu,
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
