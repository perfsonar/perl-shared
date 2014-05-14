package perfSONAR_PS::Utils::Host;

use strict;
use warnings;

our $VERSION = 3.3;

=head1 NAME

perfSONAR_PS::Utils::Host

=head1 DESCRIPTION

A module that provides functions for querying information about the host on
which the application is running. 

=head1 API

=cut

use base 'Exporter';
use Params::Validate qw(:all);
use Net::Interface;

our @EXPORT_OK = qw( get_ips get_ethernet_interfaces get_interface_addresses get_interface_speed get_interface_mtu);

=head2 get_ips()

A function that returns the non-loopback IP addresses from a host. The current
implementation parses the output of the /sbin/ifconfig command to look for the
IP addresses.

=cut

sub get_ips {
    my $parameters = validate( @_, { by_interface => 0, } );
    my $by_interface = $parameters->{by_interface};

    my %ret_interfaces = ();

    my $IFCONFIG;
    open( $IFCONFIG, "-|", "/sbin/ifconfig" ) or return;
    my $is_loop = 0;
    my $curr_interface;
    while ( <$IFCONFIG> ) {
        if ( /^(\S+)\s*Link encap:([^ ]+)/ ) {
            $curr_interface = $1;
            if ( lc( $2 ) eq "local" ) {
                $is_loop = 1;
            }
            else {
                $is_loop = 0;
            }
        }

        next if $is_loop;

        unless ($ret_interfaces{$curr_interface}) {
            $ret_interfaces{$curr_interface} = [];
        }

        if ( /inet addr:(\d+\.\d+\.\d+\.\d+)/ ) {
            push @{ $ret_interfaces{$curr_interface} }, $1;
        }
        elsif ( /inet6 addr: (\d*:[^\/ ]*)(\/\d+)? +Scope:Global/ ) {
            push @{ $ret_interfaces{$curr_interface} }, $1;
        }
    }
    close( $IFCONFIG );

    if ($by_interface) {
        return \%ret_interfaces;
    }
    else {
        my @ret_values = ();
	foreach my $value (values %ret_interfaces) {
            push @ret_values, @$value;
        }
        return @ret_values;
    }
}

sub get_ethernet_interfaces {
    my @ret_interfaces = ();

    my $IFCONFIG;
    open( $IFCONFIG, "-|", "/sbin/ifconfig -a" ) or return;
    while ( <$IFCONFIG> ) {
        if ( /^(\S*).*Link encap:([^ ]+)/ ) {
            if ( lc( $2 ) ne "local" ) {
                push @ret_interfaces, $1;
            }
        }
    }
    close( $IFCONFIG );

    return @ret_interfaces;
}

sub get_interface_addresses {
    my $parameters = validate( @_, { interface => 1, } );
    my $interface = $parameters->{interface};

    my $ips = get_ips({ by_interface => 1 });

    if ($ips->{$interface}) {
        return @{ $ips->{$interface} };
    }
    else {
        return [];
    }
}

sub get_interface_speed {
    my $parameters = validate( @_, { interface_name => 0, } );
    my $interface_name = $parameters->{interface_name};
    
    my $speed = 0;
    my $ETHTOOL;
    open( $ETHTOOL, "-|", "/sbin/ethtool $interface_name" ) or return;
    while ( <$ETHTOOL> ) {
        if ( /^\s*Speed:\s+(\d+)\s*(\w)/ ) {
            $speed = $1;
            my $units = $2;
            if($units eq 'M'){
                $speed *= 10**6;
            }elsif($units eq 'G'){
                $speed *= 10**9;
            }elsif($units eq 'T'){
                $speed *= 10**12;
            }
            last;
        }
    }
    close( $ETHTOOL );
    
    return $speed;
}

sub get_interface_mtu {
	my $parameters = validate( @_, { interface_name => 1, } );
    my $interface_name = $parameters->{interface_name};
    my @all_ifs = Net::Interface->interfaces();
    foreach my $if (@all_ifs){
        if($if->name eq $interface_name  && $if->mtu){
          return $if->mtu;
        }
    }
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
