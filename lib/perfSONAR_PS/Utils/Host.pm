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
use Log::Log4perl qw(get_logger);

use Net::Interface qw/mac_bin2hex/;
use Net::CIDR;
use Net::IP;
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use Data::Validate::Domain qw(is_hostname);
use Data::Dumper;
use URI;

use Sys::Statistics::Linux;

use perfSONAR_PS::Utils::DNS qw(reverse_dns_multi);

my $logger = get_logger(__PACKAGE__);

our @EXPORT_OK = qw(
    get_ips
    get_ethernet_interfaces
    get_interface_addresses
    get_interface_addresses_by_type
    get_interface_speed
    get_interface_mtu
    get_interface_mac
    discover_primary_address

    get_ntp_info

    get_operating_system_info
    get_processor_info
    get_tcp_configuration
    get_dmi_info
    
    get_health_info

    is_auto_updates_on

    is_ip_or_hostname
    is_web_url
);

=head2 get_ips()

A function that returns the non-loopback IP addresses from a host. The current
implementation parses the output of the /sbin/ip command to look for the
IP addresses.

=cut

sub get_ips {
    my $parameters = validate( @_, { by_interface => 0, } );
    my $by_interface = $parameters->{by_interface};

    my %ret_interfaces = ();

    my $is_loopback = 0;
    my $curr_interface;
    open( my $IP_ADDR, "-|", "/sbin/ip addr show" ) or return;
    while ( <$IP_ADDR> ) {
        if ( /^\d+: ([^ ]+?)(@[^ ]+)?: ([^ ]+)/ ) {
            $curr_interface = $1;
            if ( $3 =~ /\bLOOPBACK\b/ ) {
                $is_loopback = 1;
            }
            else {
                $is_loopback = 0;
            }
        }

        next if $is_loopback;

        unless ($ret_interfaces{$curr_interface}) {
            $ret_interfaces{$curr_interface} = [];
        }

        if ( /inet (\d+\.\d+\.\d+\.\d+)/ ) {
            push @{ $ret_interfaces{$curr_interface} }, $1;
        }
        elsif ( m|inet6 ([[:xdigit:]:]+)/\d+ scope global| ) {
            push @{ $ret_interfaces{$curr_interface} }, $1;
        }
    }
    close( $IP_ADDR );

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

    open( my $IP_ADDR, "-|", "/sbin/ip addr show" ) or return;
    while ( <$IP_ADDR> ) {
        if ( /^\d+: ([^ ]+?)(@[^ ]+)?: (.+)$/ ) {
            my $ifname = $1;
            my $ifdetails = $3;
            if ( $ifdetails !~ /\bLOOPBACK\b/ && $ifdetails =~ /\bstate UP\b/) {
                push @ret_interfaces, $ifname;
            }
        }
    }
    close( $IP_ADDR );

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
        return ();
    }
}

sub get_interface_addresses_by_type {

    my $parameters = validate( @_, { interface => 1, } );
    my $interface = $parameters->{interface};


    my @addresses = get_interface_addresses({interface => $interface });
    my @ipv4_addresses;
    my @ipv6_addresses;
    my @dns_names;

    foreach my $address (@addresses){
        if (is_ipv4($address)){
            push @ipv4_addresses, $address
        }elsif (Net::IP::ip_is_ipv6($address)){ # TODO: double check this. should it be is_ipv6 instead?
            push @ipv6_addresses, $address
        }
    }

    my $result;
    $result->{ipv4_address} = \@ipv4_addresses;
    $result->{ipv6_address} = \@ipv6_addresses;

    return $result;

}

sub get_interface_speed {
    my $parameters = validate( @_, { interface_name => 0, } );
    my $interface_name = $parameters->{interface_name};
   
    my $speed = 0;

    # Try to read the speed from /sys since that's readable whether or not
    # you're root.
    my $speed_file = "/sys/class/net/".$interface_name."/speed";
    if (-f $speed_file) {
        my $raw_speed = `cat $speed_file`;
        chomp($raw_speed);
        $speed = $raw_speed * 10**6 if $raw_speed;
    }

    unless ($speed) {
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
    }
 
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

sub get_interface_mac {
	my $parameters = validate( @_, { interface_name => 1, } );
    my $interface_name = $parameters->{interface_name};
    my @all_ifs = Net::Interface->interfaces();

    foreach my $if (@all_ifs){
        next unless $if->name eq $interface_name;
        my $info = $if->info();

        if ($info->{mac}) {
            return mac_bin2hex($info->{mac});
        }

        last;
    }

    return;
}


=head2 discover_primary_address ($name)

Find the 'primary' address for communicating with the outside world.

=cut

sub discover_primary_address {
    my $parameters = validate( @_, { interface => 0, allow_rfc1918 => 0, disable_ipv4_reverse_lookup => 0, disable_ipv6_reverse_lookup => 0 } );
    my $interface = $parameters->{interface};
    my $allow_rfc1918 = $parameters->{allow_rfc1918};
    my $disable_ipv4_reverse_lookup = $parameters->{disable_ipv4_reverse_lookup};
    my $disable_ipv6_reverse_lookup = $parameters->{disable_ipv6_reverse_lookup};

    my $ips_by_iface = {};

    if ( $interface ) {
        my @ips = get_interface_addresses( { interface => $interface } );
        if(@ips){
            $ips_by_iface = { $interface => \@ips };   
        }
        
    } else {
        # If they've not told us which interface to use it's time to guess.
        $ips_by_iface = get_ips({ by_interface => 1 });
    }

    my $chosen_address;
    my $ipv4_address;
    my $ipv6_address;
    my $chosen_dns_name;
    my $ipv4_dns_name;
    my $ipv6_dns_name;
    my $chosen_interface;
    my $ipv4_interface;
    my $ipv6_interface;
    my $interface_speed;
    my $interface_mtu;
    my $interface_mac;
    
    my @all_ips = ();
    foreach my $iface ( keys %$ips_by_iface ) {
        foreach my $ip (@{ $ips_by_iface->{$iface} }) {
            push @all_ips, $ip;
        }
    }

    my $reverse_dns_mapping = reverse_dns_multi({ addresses => \@all_ips, timeout => 10 }); # don't wait more than 10 seconds.

    # Try to find an address with an ipv4 address with that resolves to something
    unless ( $disable_ipv4_reverse_lookup) {
        foreach my $iface ( keys %$ips_by_iface ) {
            foreach my $ip ( @{ $ips_by_iface->{$iface } } ) {
                my @private_list = ( '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16' );

                next unless (is_ipv4( $ip ));
                $logger->debug("$ip is ipv4");
                next unless (defined $reverse_dns_mapping->{$ip} and $reverse_dns_mapping->{$ip}->[0]);
                $logger->debug("$ip has a DNS name: ". $reverse_dns_mapping->{$ip}->[0]);
                next unless ($allow_rfc1918 or not Net::CIDR::cidrlookup( $ip, @private_list ));
                $logger->debug("$ip isn't private or we're okay with private addresses");

                my $dns_name = $reverse_dns_mapping->{$ip}->[0];

                unless ( $chosen_address ) { 
                    $chosen_dns_name = $dns_name;
                    $chosen_address = $ip;
                    $chosen_interface = $iface;
                }
    
                unless ( $ipv4_address ) {
                    $ipv4_dns_name = $dns_name;
                    $ipv4_address   = $ip;
                    $ipv4_interface = $iface;
                }

                last;
            }
        }
    }

    # Try to find an ipv6 address that resolves to something
    unless ( $disable_ipv6_reverse_lookup or ( $chosen_address and $ipv6_address )) {
        foreach my $iface ( keys %$ips_by_iface ) {
            foreach my $ip ( @{ $ips_by_iface->{$iface } } ) {
                next unless (Net::IP::ip_is_ipv6( $ip ));
                $logger->debug("$ip is IPv6");
                next unless (defined $reverse_dns_mapping->{$ip} and $reverse_dns_mapping->{$ip}->[0]);
                $logger->debug("$ip has a DNS name: ". $reverse_dns_mapping->{$ip}->[0]);
    
                my $dns_name = $reverse_dns_mapping->{$ip}->[0];
    
                unless ( $chosen_address ) { 
                    $chosen_dns_name = $dns_name;
                    $chosen_address = $ip;
                    $chosen_interface = $iface;
                }

                unless ( $ipv6_address ) {
                    $ipv6_dns_name = $dns_name;
                    $ipv6_address   = $ip;
                    $ipv6_interface = $iface;
                }

                last;
            }
        }
    }

    # Try to find an ipv4 address
    unless ( $chosen_address and $ipv4_address ) {
        foreach my $iface ( keys %$ips_by_iface ) {
            foreach my $ip ( @{ $ips_by_iface->{$iface } } ) {

                my @private_list = ( '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16' );

                next unless (is_ipv4( $ip ));
                $logger->debug("$ip is IPv4");
                next unless ($allow_rfc1918 or not Net::CIDR::cidrlookup( $ip, @private_list ));
                $logger->debug("$ip isn't private or we're okay with private addresses");

                unless ( $chosen_address ) { 
                    $chosen_dns_name = "";
                    $chosen_address = $ip;
                    $chosen_interface = $iface;
                }

                unless ( $ipv4_address ) {
                    
                    $ipv4_dns_name = "";
                    $ipv4_address   = $ip;
                    $ipv4_interface = $iface;
                }
            }
            last if ($ipv4_address and $chosen_address);
        }
    }

    # Try to find an ipv6 address
    unless ( $chosen_address and $ipv6_address ) {
        foreach my $iface ( keys %$ips_by_iface ) {
            foreach my $ip ( @{ $ips_by_iface->{$iface } } ) {
                next unless (Net::IP::ip_is_ipv6( $ip ));
                $logger->debug("$ip is IPv6");

                unless ( $chosen_address ) { 
                    $chosen_dns_name = "";
                    $chosen_address = $ip;
                    $chosen_interface = $iface;
                }

                unless ( $ipv6_address ) {
                    $ipv4_dns_name = "";
                    $ipv6_address   = $ip;
                    $ipv6_interface = $iface;
                }
            }
            last if ($ipv6_address and $chosen_address);
        }
    }

    #get the interface speed
    if($chosen_interface){
        $interface_speed = get_interface_speed({interface_name => $chosen_interface});
        $interface_mtu = get_interface_mtu({interface_name => $chosen_interface});
        $interface_mac = get_interface_mac({interface_name => $chosen_interface});
    }

    if ($chosen_address) {
        $logger->debug("Selected $chosen_interface/$chosen_address as the primary address");
    }
    else {
        $logger->debug("No primary address found");
    }

    if ($ipv4_address) {
        $logger->debug("Selected $ipv4_interface/$ipv4_address as the primary ipv4 address");
    }
    else {
        $logger->debug("No primary ipv4 address found");
    }

    if ($ipv6_address) {
        $logger->debug("Selected $ipv6_interface/$ipv6_address as the primary ipv6 address");
    }
    else {
        $logger->debug("No primary ipv6 address found");
    }

    return {
        primary_dns_name => $chosen_dns_name,
        primary_address => $chosen_address,
        primary_ipv6 => $ipv6_address,
        primary_ipv4 => $ipv4_address,
        primary_ipv4_dns_name => $ipv4_dns_name,
        primary_ipv6_dns_name => $ipv6_dns_name,
        primary_address_iface => $chosen_interface,
        primary_ipv6_iface => $ipv6_interface,
        primary_ipv4_iface => $ipv4_interface,
        primary_iface_speed => $interface_speed,
        primary_iface_mtu => $interface_mtu,
        primary_iface_mac => $interface_mac,
    };
}

sub get_ntp_info {
    my $ntp;

    my $ntp_result = `/usr/sbin/ntpdc -p`;

    my @ntp_response = split /\n/, $ntp_result;
    
    my $result;
    foreach my $line (@ntp_response){
        my @ntp_fields = split /\s+/, $line;
        if($line =~ m/^\*/){
            print @ntp_fields;
            my @host = split /\*/, $ntp_fields[0];
            $result->{host} = $host[1];
            $result->{address} = $ntp_fields[1];
            $result->{stratum} = $ntp_fields[2];
            $result->{polling_interval} = $ntp_fields[3];
            $result->{reach} = $ntp_fields[4];
            $result->{delay} = $ntp_fields[5];
            $result->{offset} = $ntp_fields[6];
            $result->{dispersion} = $ntp_fields[7];
            last;
        }
    }

    return $result;

}

sub get_operating_system_info {
    my ($distribution_name, $distribution_version, $os_type, $kernel_version);

    # TODO: We could use the perl module Linux::Distribution https://metacpan.org/pod/Linux::Distribution
    if (open(FILE, "/etc/redhat-release")) {
        # Redhat style
        my @lines = <FILE>;
        close(FILE);
        if(@lines > 0){
            chomp $lines[0];
            my @osinfo = split ' release ', $lines[0];
            if(@osinfo >= 2){
                $distribution_name = $osinfo[0];
                $distribution_version = $osinfo[1];
            }
        }
    } elsif (open(FILE, "/etc/lsb-release")) {
        # LSB (Ubuntu) style
        while(<FILE>) {
            if (/^DISTRIB_ID=(.*)$/) {
                $distribution_name = $1;
            }
            if (/^DISTRIB_RELEASE=(.*)$/) {
                $distribution_version = $1;
            }
        }
        close(FILE);
    } elsif (open(FILE, "/etc/debian_version")) {
        # Debian style (must come after Ubuntu style because also existing on Ubuntu hosts)
        my @lines = <FILE>;
        close(FILE);
        if(@lines > 0){
            chomp $lines[0];
            $distribution_name = "Debian";
            $distribution_version = $lines[0];
        }
    }

    $os_type = _call_sysctl("kernel.ostype");

    $kernel_version = _call_sysctl("kernel.osrelease");

    return {
        os_name => $os_type,
        kernel_version => $kernel_version,
        distribution_name => $distribution_name,
        distribution_version => $distribution_version
    };
}

sub get_processor_info {
    my %lscpu_parse_map = (
        'CPU MHz' => 'speed',
        'CPU socket(s)' => 'count',
        'Socket(s)' => 'count', #alternative label for sockets
        'CPU(s)' => 'cores',
    );
     my %cpuinfo_parse_map = (
        'model name' => 'model_name',
    );
    my %cpuinfo = ();
    
    my @lscpu = `lscpu 2>/dev/null`;
    unless($?){
        foreach my $line(@lscpu){
            chomp $line ;
            my @cols = split /\:\s+/, $line;
            next if(@cols != 2);
        
            if($lscpu_parse_map{$cols[0]}){
                $cpuinfo{$lscpu_parse_map{$cols[0]}} = $cols[1];
            }
        }
    }
    
    my @cpuinfo = `cat /proc/cpuinfo`;
    unless($?){
        foreach my $line(@cpuinfo){
            chomp $line ;
            my @cols = split /\s*:\s*/, $line;
            next if(@cols != 2);
            if($cpuinfo_parse_map{$cols[0]}){
                $cpuinfo{$cpuinfo_parse_map{$cols[0]}} = $cols[1];
            }
        }
    }
     
    return \%cpuinfo;
}

sub get_dmi_info {
    my %dmiinfo = ();
    my @dmi_vars = ('sys_vendor', 'product_name');
    my @vm_prod_patterns = ("^VMware", "^VirtualBox", , "^KVM", '^Virtual Machine$');
    
    foreach my $dmi_var(@dmi_vars){
        #dmidecode requires root, so access files instead
        my $dmi_path = "/sys/devices/virtual/dmi/id/$dmi_var";
        my @dmidecode = `cat $dmi_path` if -f $dmi_path;
        unless($?){
            #should just be one line
            foreach my $line(@dmidecode){
                chomp $line ;
                $dmiinfo{$dmi_var} = $line;
                last;
            }
        }
    }
    
    #figure out if this is a VM
    $dmiinfo{'is_virtual_machine'} = 0; #0 means unknown
    if( exists $dmiinfo{'product_name'} ){
        foreach my $vm_prod_pattern(@vm_prod_patterns){
            $dmiinfo{'is_virtual_machine'} = 1 if($dmiinfo{'product_name'} =~ /$vm_prod_pattern/);
        }
    } else {
        # Check if we're on a Xen guest
        my $dmesg_path = "/var/log/dmesg";
        my $xenboot = system('grep -q "Booting paravirtualized kernel on Xen" ' . $dmesg_path) if -f $dmesg_path;
        if ($xenboot eq 0) {
            # We're on a Xen guest
            $dmiinfo{'is_virtual_machine'} = 1;
            $dmiinfo{'product_name'} = "Xen";
            $dmiinfo{'sys_vendor'} = "Xen Project";
        }
    }
    
    return \%dmiinfo;
}

sub get_health_info{
    
    my $lxs = Sys::Statistics::Linux->new(
        cpustats  => 1,
        memstats  => 1,
        diskusage => 1,
        loadavg   => 1,
    );

    sleep 1;
    my $stat = $lxs->get;
    
    my $result;
    #the following helps to decouple the output from the underlyign package used
    $result->{'cpustats'}=$stat->{'cpustats'};
    $result->{'memstats'}=$stat->{'memstats'};
    $result->{'diskusage'}=$stat->{'diskusage'};
    $result->{'loadavg'}=$stat->{'loadavg'}; 
    return $result;
}

sub get_tcp_configuration {
    my ($self) = @_;

    return {
        tcp_cc_algorithm => _call_sysctl("net.ipv4.tcp_congestion_control"),
        tcp_max_buffer_send => _call_sysctl("net.core.wmem_max"),
        tcp_max_buffer_recv => _call_sysctl("net.core.rmem_max"),
        tcp_autotune_max_buffer_send => _max_buffer_auto("net.ipv4.tcp_wmem"),
        tcp_autotune_max_buffer_recv => _max_buffer_auto("net.ipv4.tcp_rmem"),
        tcp_max_backlog => _call_sysctl("net.core.netdev_max_backlog"),
    };
}

sub is_auto_updates_on{

    my ($self) = @_;

    my $enabled = "enabled";

    my $result = `/etc/init.d/yum-cron status`;

    if(index($result, $enabled) != -1){
        return 1;
    }else{
        return 0;
    }
}

sub is_ip_or_hostname {
    my $parameters = validate( @_, { 
            address => 1,
            required => 0,
        } );
    my @addresses;
    if (  ref( $parameters->{address} ) eq 'ARRAY') {
        @addresses = @{ $parameters->{address} };
    } else {
        @addresses = ( $parameters->{address} );
    }
    my $required = 1;
    $required = $parameters->{required} if defined $parameters->{required};
    return 0 if (not @addresses ) || @addresses == 0;
    my $result = 0;
    foreach my $address (@addresses) {
        if ( is_ipv4($address) ) {
            $result = 1;
        } elsif ( is_ipv6($address) ) {
            $result = 1;
        } elsif ( is_hostname($address) ) {
            $result = 1;
        } elsif ( $address eq '' && !$required ) {
            $result = 1;
        } else {
            return 0;
        }
    }
    return $result;
}

sub is_web_url {
    my $parameters = validate( @_, { 
            address => 1,
            required => 0,
        } );
    my @addresses;
    if (  ref( $parameters->{address} ) eq 'ARRAY') {
        @addresses = @{ $parameters->{address} };
    } else {
        @addresses = ( $parameters->{address} );
    }
    my $required = 1;
    $required = $parameters->{required} if defined $parameters->{required};
    return 0 if (not @addresses ) || @addresses == 0;
    foreach my $address (@addresses) {
        my $uri = URI->new($address);
        my $scheme = $uri->scheme;
        return 0 if $uri eq '' && $required;
        if ( !defined ($scheme) || ( $scheme ne "http" && $scheme ne "https" ) ) {
            return 0;
        }
    }
    return 1;
}

sub _call_sysctl {
    my ($var_name) = @_;

    my $result = `sysctl $var_name`;
    if($?){
        return;
    }
    unless($result){
        return;
    }
    my @parts = split '=', $result;
    if(@parts != 2){
        return;
    }
    chomp $parts[1];
    $parts[1] =~ s/^\s+//;
    
    return $parts[1];
}

sub _max_buffer_auto {
    my($sysctl_var) = @_;
    
    my $sysctl_val = _call_sysctl($sysctl_var);
    if(!$sysctl_val){
        return;
    }
    
    my @parts = split /\s+/, $sysctl_val;
    if(@parts != 3){
        return;
    }
    
    return $parts[2];
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
