package perfSONAR_PS::RegularTesting::Utils;

use strict;
use warnings;

our $VERSION = 3.1;

=head1 NAME

perfSONAR_PS::RegularTesting::Utils;

=head1 DESCRIPTION

A module that provides some utility functions used by the Regular Testing
infrastructure.

=head1 API

=cut

use base 'Exporter';
use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);

use Data::Validate::Domain qw(is_hostname);
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use Net::IP;

use Math::Int64 qw(uint64 uint64_to_number);
use perfSONAR_PS::Utils::DNS qw(resolve_address);

use DateTime;

our @EXPORT_OK = qw( parse_target owpdelay owptime2datetime owptstampi2datetime datetime2owptime datetime2owptstampi choose_endpoint_address );

my $logger = get_logger(__PACKAGE__);

use constant JAN_1970 => 0x83aa7e80;    # offset in seconds
my $scale = 2**32;

=head2 parse_target(target => 1)

=cut
sub parse_target {
    my $parameters = validate( @_, { target => 1 });
    my $target = $parameters->{target};

    my ($address, $port);

    if ($target =~ /^\[(.*)\]:(\d+)$/) {
        $address = $1;
        $port    = $2;
    }
    elsif ($target =~ /^\[(.*)\]$/) {
        $address = $1;
    }
    elsif ($target =~ /^(.*):(\d+)$/) {
        $address = $1;
        $port    = $2;
    }
    else {
        $address = $target;
    }

    return { address => $address, port => $port };
}

=head2 owpdelay($start, $end)

=cut
sub owpdelay {
    my ($start, $end) = @_;

    return ($end - $start)/$scale;
}

=head2 owptime2datetime($owptime)

=cut
sub owptime2datetime {
    my ($owptime) = @_;

    my $tstamp = uint64($owptime);
    $tstamp = uint64_to_number(($tstamp >> 32) & 0xFFFFFFFF);
    $tstamp -= JAN_1970;
    return DateTime->from_epoch(epoch => $tstamp);
}

=head2 owptime2datetime($owptime)

=cut
sub owptstampi2datetime{
    my ($owptime) = @_;

    $owptime -= JAN_1970;

    return DateTime->from_epoch(epoch => $owptime);
}



=head2 datetime2owptime($datetime)

=cut
sub datetime2owptime {
    my ($datetime) = @_;

    my $bigtime = uint64($datetime->epoch());
    $bigtime = ($bigtime + JAN_1970) * $scale;
    print "Big Time: $bigtime\n";
    $bigtime += $datetime->nanosecond();
    $bigtime =~ s/^\+//;
    return uint64_to_number($bigtime);
}

=head2 datetime2owptstampi($datetime)

=cut
sub datetime2owptstampi{
    my ($datetime) = @_;

    my $bigtime = uint64(datetime2owptime($datetime));

    return uint64_to_number($bigtime>>32);
}

=head2 choose_endpoint_address()

=cut
sub choose_endpoint_address{
    my $parameters = validate( @_, { ifname => 1, interface_ips => 1, target_address => 1, force_ipv4 => 1,  force_ipv6 => 1});
    my $ifname = $parameters->{ifname};
    my $interface_ips = $parameters->{interface_ips};
    my $target_address = $parameters->{target_address};
    my $force_ipv4 = $parameters->{force_ipv4};
    my $force_ipv6 = $parameters->{force_ipv6};
    my $local_address;
    
    #if an interface was given, figure out which address to use
    if($force_ipv4){
        unless(@{$interface_ips->{ipv4_address}}){
            return (-1, "No ipv4 address for interface " . $ifname . " but force_ipv4 enabled");
        }
        $local_address = $interface_ips->{ipv4_address}->[0]; #use first one in list
    }elsif($force_ipv6){
        unless(@{$interface_ips->{ipv6_address}}){
            return (-1, "No ipv6 address for interface " . $ifname . " but force_ipv6 enabled");
        }
        $local_address = $interface_ips->{ipv6_address}->[0]; #use first one in list
    }elsif(is_ipv4($target_address)){
        unless(@{$interface_ips->{ipv4_address}}){
            return (-1, "No ipv4 address for interface " . $ifname . " but target $target_address is IPv4");
        }
        $local_address = $interface_ips->{ipv4_address}->[0]; #use first one in list
    }elsif(is_ipv6($target_address)){
        unless(@{$interface_ips->{ipv6_address}}){
            return (-1, "No ipv6 address for interface " . $ifname . " but target $target_address is IPv6");
        }
        $local_address = $interface_ips->{ipv6_address}->[0]; #use first one in list
    }else{
        my @target_ips = resolve_address($target_address);
        my $ipv6;
        my $ipv4;
        foreach my $target_ip(@target_ips){
            if(is_ipv4($target_ip)){
                $ipv4 = $target_ip;
            }elsif(is_ipv6($target_ip)){
                $ipv6 = $target_ip;
            }
        }
        if($ipv6 && @{$interface_ips->{ipv6_address}}){
            $local_address = $interface_ips->{ipv6_address}->[0];
        }elsif($ipv4 && @{$interface_ips->{ipv4_address}}){
            $local_address = $interface_ips->{ipv4_address}->[0];
        }else{
            return (-1, "Unable to find a matching pair of IPv4 or IPv6 addresses for interface " . $ifname . " and target address $target_address"); 
        }
    }
    
    return (0, $local_address);
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
