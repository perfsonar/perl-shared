package perfSONAR_PS::NPToolkit::Services::NetworkBase;

use strict;
use warnings;

use URI;
use URI::Split qw(uri_split);
use Net::Ping;

use perfSONAR_PS::Utils::Host qw(get_ips);
use perfSONAR_PS::Utils::DNS  qw(reverse_dns_multi);

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub get_addresses {
    return [];
}

sub check_available {
    my ( $self ) = @_;

    my $addresses = $self->get_addresses();
    foreach my $address ( @$addresses ) {
        my ($scheme, $host_port, @others) = uri_split($address);

        if ($scheme eq "http" or $scheme eq "https") {
            my ($status, $res) = https_get(url => $address);
            if ($status == 0) {
                return 1;
            }
        }
        elsif (is_ipv4($address) or is_ipv6($address) or is_hostname($address)) {
            my $ping = Net::Ping->new( "external" );
            if ( $ping->ping( $address, 1 ) ) {
                return 1;
            }
        }
        elsif ($scheme eq "tcp") {
            my $uri = URI->new("http://".$host_port); # Hacky way of parsing the [::1]:80 vs 127.0.0.1:80 vs ...
            my $sock = IO::Socket::INET6->new( PeerAddr => $uri->host, PeerPort => $uri->port, Proto => 'tcp', Timeout => 5 );
            if ( $sock ) {
                $sock->close;

                return 1;
            }
        }
    }

    return 0;
}

sub lookup_interfaces {
    my ( $self ) = @_;

    my @ips = get_ips();

    my $resolved_addresses = reverse_dns_multi({ addresses => \@ips, timeout => 2 });

    my %ret_addresses = ();
    foreach my $ip (@ips) {
        if ($resolved_addresses->{$ip} and scalar(@{ $resolved_addresses->{$ip} }) > 0) {
            foreach my $addr (@{ $resolved_addresses->{$ip} }) {
                $ret_addresses{$addr} = 1;
            }
        } else {
            $ret_addresses{$ip} = 1;
        }
    }

    my @ret_addrs = keys %ret_addresses;

    return @ret_addrs;
}

1;
