package perfSONAR_PS::Utils::DNS;

use strict;
use warnings;

our $VERSION = 3.3;

=head1 NAME

perfSONAR_PS::Utils::DNS

=head1 DESCRIPTION

A module that provides utility methods for interacting with DNS servers.  This
module provides a set of methods for interacting with DNS servers. This module
IS NOT an object, and the methods can be invoked directly. The methods need to
be explicitly imported to use them.

=head1 API

=cut

use base 'Exporter';

use Params::Validate qw(:all);
use Net::DNS;
use NetAddr::IP;
use Regexp::Common;
use Data::Dumper;
use Socket;
use Socket6 qw(inet_ntop);
use IO::Socket::INET6;

our @EXPORT_OK = qw( reverse_dns resolve_address resolve_address_multi reverse_dns_multi query_location discover_source_address );

=head2 resolve_address ($name)

Resolve an ip address to a DNS name.

=cut

sub resolve_address {
    my ( $name, $timeout ) = @_;

    $timeout = 2 unless ($timeout);

    my $resolved_hostnames = resolve_address_multi({ addresses => [ $name ], timeout => $timeout });

    my @addresses = ();

    if ($resolved_hostnames && $resolved_hostnames->{$name}) {
        foreach my $hostname (@{ $resolved_hostnames->{$name} }) {
            push @addresses, $hostname;
        }
    }

    return @addresses;
}

=head2 reverse_dns ($ip)

Does a reverse DNS lookup on the given ip address. The ip must be in IPv4
dotted decimal or IPv6 colon-separated decimal form.

=cut

sub reverse_dns {
    my ( $ip, $timeout ) = @_;

    my $tmp_ip = NetAddr::IP->new( $ip );
    unless ( $tmp_ip ) {
        return;
    }

    my $addr = $tmp_ip->addr();
    unless ( $addr ) {
        return;
    }

    $timeout = 2 unless ($timeout);

    my $resolved_hostnames = reverse_dns_multi({ addresses => [ $ip ], timeout => $timeout });

    my $hostnames;

    if ($resolved_hostnames && $resolved_hostnames->{$ip}) {
        $hostnames = $resolved_hostnames->{$ip};
    }
    else {
        $hostnames = [];
    }

    if (wantarray) {
        return @$hostnames;
    }
    else {
        return $hostnames->[0];
    }
}

=head2 resolve_address_multi({ addresses => 1, timeout => 0 })
Performs a dns lookup of all the addresses specified. If the timeout parameter
is specified, the function will return after that number of seconds, whether
data is returned or not. The default timeout is 60 seconds.
=cut
sub resolve_address_multi {
    my $parameters = validate( @_, { addresses => 1, timeout => 0 } );

    my $end_time;

    unless ($parameters->{timeout}) {
        $parameters->{timeout} = 60;
    }

    $end_time = time + $parameters->{timeout};

    my $res   = Net::DNS::Resolver->new;

    my @socket_map = ();

    foreach my $addr (@{ $parameters->{addresses} }) {
        next unless ($addr);

        #v4 Lookup
        my $bgsock = $res->bgsend($addr);
        my %pair = ( socket => $bgsock, address => $addr );
        push @socket_map, \%pair;
        #v6 Lookup
        my $bgsock6 = $res->bgsend($addr, 'AAAA');
        my %pair6 = ( socket => $bgsock6, address => $addr );
        push @socket_map, \%pair6;
    }

    my %results = ();

    while(@socket_map) {
        my $sel = IO::Select->new();

        foreach my $pair (@socket_map) {
            $sel->add($pair->{socket});
        }

        my $duration = $end_time - time;

        my @ready = $sel->can_read($duration);

        last unless (@ready);

        foreach my $sock (@ready) {
            my $addr;
            foreach my $pair (@socket_map) {
                if ($pair->{socket} == $sock) {
                    $addr = $pair->{address};
                    last;
                }
            }

            next unless ($addr);

            my $query = $res->bgread($sock);
            
            $results{$addr} = () if(!$results{$addr});
            my @addresses = ();
            foreach my $ans ( $query->answer ) {
                next if ( $ans->type ne "A" && $ans->type ne "AAAA");
                push @{ $results{$addr} }, $ans->address;
            }

            # Create a new socket map
            my @new_socket_map = ();
            foreach my $pair (@socket_map) {
                next if ($pair->{socket} == $sock);

                push @new_socket_map, $pair;
            }
            @socket_map = @new_socket_map;
        }
   }

   return \%results;
}

=head2 reverse_dns_multi({ addresses => 1, timeout => 0 })
Performs a reverse dns lookup of all the addresses specified. If the timeout
parameter is specified, the function will return after that number of seconds,
whether data is returned or not. The default timeout is 60 seconds.
=cut
sub reverse_dns_multi {
    my $parameters = validate( @_, { addresses => 1, timeout => 0 } );

    my $end_time;

    unless ($parameters->{timeout}) {
        $parameters->{timeout} = 60;
    }

    $end_time = time + $parameters->{timeout};

    my $res   = Net::DNS::Resolver->new;
    my %results = ();
    my @socket_map = ();

    foreach my $addr (@{ $parameters->{addresses} }) {
        next unless ($addr);

        my $bgsock = $res->bgsend($addr);

        my %pair = ( socket => $bgsock, address => $addr );
        push @socket_map, \%pair;
        $results{$addr} = [];
    }

    while(@socket_map) {
        my $sel = IO::Select->new();

        foreach my $pair (@socket_map) {
            $sel->add($pair->{socket});
        }

        my $duration = $end_time - time;

        my @ready = $sel->can_read($duration);

        last unless (@ready);

        foreach my $sock (@ready) {
            my $addr;
            foreach my $pair (@socket_map) {
                if ($pair->{socket} == $sock) {
                    $addr = $pair->{address};
                    last;
                }
            }

            next unless ($addr);

            my $query = $res->bgread($sock);

            my @addresses = ();
            foreach my $ans ( $query->answer ) {
                next if ( $ans->type ne "PTR" );
                push @addresses, $ans->ptrdname;
            }
            $results{$addr} = \@addresses;

            # Create a new socket map
            my @new_socket_map = ();
            foreach my $pair (@socket_map) {
                next if ($pair->{socket} == $sock);

                push @new_socket_map, $pair;
            }
            @socket_map = @new_socket_map;
        }
   }

   return \%results;
}

=head2 query_location ($address)

Returns the latitude and longitude of the specified address if it has a DNS LOC
record. The return value is an array of the form
($status, { latitude => $latitude, longitude => $longitude }). Where $status is
0 on success, and -1 on error. Note: latitude and longitude may be undefined if
the address has no LOC record.

=cut

sub query_location {
    my ( $address ) = @_;

    my $res   = Net::DNS::Resolver->new;
    my $query = $res->search( $address , "LOC" );

    unless ( $query ) {
        return (-1, "Couldn't find location");
    }

    my ($latitude, $longitude);

    foreach my $ans ( $query->answer ) {
        next if ( $ans->type ne "LOC" );
        ($latitude, $longitude) = $ans->latlon;
    }

    return (0, { latitude => $latitude, longitude => $longitude });
}

sub discover_source_address {
    my $parameters = validate( @_, { address => 1, local_address => 0, force_ipv4 => 0, force_ipv6 => 0 } );
    my $address = $parameters->{address};
    my $local_address = $parameters->{local_address};
    my $force_ipv4 = $parameters->{force_ipv4};
    my $force_ipv6 = $parameters->{force_ipv6};
    
    # Create a UDP socket destined for the specified address
    my $sock;
    unless($force_ipv4){
        $sock = IO::Socket::INET6->new(LocalAddr => $local_address, PeerAddr => $address, PeerPort => '80', Proto => 'udp', Domain => AF_INET6);
    }
    unless($sock || $force_ipv6){
        $sock = IO::Socket::INET6->new(LocalAddr => $local_address, PeerAddr => $address, PeerPort => '80', Proto => 'udp', Domain => AF_INET);
    }
    return unless $sock;

    # Grab the local end of the newly-created socket 
    my $addr = $sock->sockaddr();
    return unless $addr;

    # Convert the address to a string
    return inet_ntop($sock->sockdomain(), $addr);
}

1;

__END__

=head1 SEE ALSO

L<Net::DNS>, L<NetAddr::IP>, L<Regexp::Common>

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS git repository is located at:

  https://code.google.com/p/perfsonar-ps/

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id$

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
