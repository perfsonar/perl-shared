package perfSONAR_PS::Utils::NTP;

use strict;
use warnings;

our $VERSION = 3.3;

=head1 NAME

perfSONAR_PS::Utils::NTP

=head1 DESCRIPTION

A module that provides utility methods for interacting with NTP servers.  This
module provides a set of methods for interacting with NTP servers. This module
IS NOT an object, and the methods can be invoked directly. The methods need to
be explicitly imported to use them.

=head1 API

=cut

use base 'Exporter';

use Socket;
use Time::HiRes qw(gettimeofday);
use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);
use IO::Select;

our @EXPORT_OK = qw( ping );

=head2 ping ($hostname => 1, port => 0, timeout => 0)

Resolve an ip address to a NTP name.

=cut

sub ping {
    my $parameters = validate( @_, { hostnames => 1, port => 0, timeout => 0} );

    my $hostnames = $parameters->{hostnames};
    my $port = $parameters->{port};
    my $timeout = $parameters->{timeout};

    $hostnames = [ $hostnames ] unless ref($hostnames) eq "ARRAY";
    $port = 123 unless $port;
    $timeout = 5 unless $timeout;

    my $retval;

    my %results = ();

    my $end_time = time + $timeout;

    eval {
        my ($status, $res);

        my @states = ();

        my $select = IO::Select->new();
        foreach my $hostname (@$hostnames) {
            eval {
                #we use the system call to open a UDP socket
                my $status = socket(my $socket, PF_INET, SOCK_DGRAM, getprotobyname("udp"));
                unless ($status) {
                    die("Socket failed: $?");
                }

                #convert hostname to ipaddress if needed
                my $ipaddr   = inet_aton($hostname);
                my $portaddr = sockaddr_in($port, $ipaddr);
                push @states, {
                    hostname => $hostname,
                    portaddr => $portaddr,
                    ipaddr   => $ipaddr,
                    socket   => $socket
                };

                $select->add($socket);
            };
            if ($@) {
                $results{$hostname}->{error} = $@;
            };
        }

        # build a message.  Our message is all zeros except for a one in the protocol version field
        # $msg in binary is 00 001 000 00000000 ....  or in C msg[]={010,0,0,0,0,0,0,0,0,...}
        #it should be a total of 48 bytes long
        my $MSG="\010"."\0"x47;

        # Send the messages
        foreach my $state (@states) {
            my ($s_seconds, $s_microseconds) = gettimeofday();

            # Send the data
            my $res = send($state->{socket}, $MSG, 0, $state->{portaddr});
            unless ($res == length($MSG)) {
                $state->{error} = "cannot send to ".$state->{hostname}."($port): $!";
                next;
            }

            $state->{start_seconds}      = $s_seconds;
            $state->{start_microseconds} = $s_microseconds;
        }

        my $remaining_time = $end_time - time;
        
        #cap time spent here a 5 seconds
        while (scalar(my @ready = $select->can_read($remaining_time < 5 ? $remaining_time : 5 )) > 0) {
            foreach my $socket (@ready) {
                my $portaddr = recv($socket, $MSG, 1024, 0);
                my $error_msg = "recv: $!" unless $portaddr;

                my ($e_seconds, $e_microseconds) = gettimeofday();

                foreach my $state (@states) {
                    next unless ($state->{socket} == $socket);

                    $state->{error} = $error_msg;
                    $state->{end_seconds} = $e_seconds;
                    $state->{end_microseconds} = $e_microseconds;
                }

                $select->remove($socket);
            }
        }

        foreach my $state (@states) {
            my $seconds;

            if ($state->{end_seconds} and $state->{end_microseconds}) {
                my $dur_seconds = ($state->{end_seconds} - $state->{start_seconds});
                my $dur_micros = ($state->{end_microseconds} - $state->{start_microseconds});
                if ($dur_micros < 0) {
                        $dur_micros = -$dur_micros;
                        $dur_seconds--;
                }
                $seconds = sprintf("%d.%06d", $dur_seconds, $dur_micros);
            }

            $results{$state->{hostname}}->{rtt} = $seconds;
            $results{$state->{hostname}}->{error} = $state->{error};
        }

        alarm 0;
    };
    if ($@ and $@ !~ /Timeout/) {
        my $msg = $@;
        return (-1, $msg);
    }

    return (0, \%results);
}

1;

__END__

=head1 SEE ALSO

L<Socket>, L<Time::HiRes>,
L<Params::Validate>,L<Log::Log4perl>,

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS git repository is located at:

  https://code.google.com/p/perfsonar-ps/

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id: NTP.pm 2640 2009-03-20 01:21:21Z zurawski $

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

