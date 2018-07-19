package perfSONAR_PS::NPToolkit::Services::TWAMP;

use strict;
use warnings;

use Data::Validate::IP qw(is_ipv6);

use base 'perfSONAR_PS::NPToolkit::Services::NetworkBase';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "TWAMP" unless $conf{description};
    $conf{process_names} = [ "twampd" ] unless $conf{process_names};
    $conf{pid_files} = [ "/var/run/twamp-server.pid" ] unless $conf{pid_files};
    $conf{init_script} = "twamp-server" unless $conf{init_script};
    $conf{can_disable} = 1;
    $conf{package_names} = [ "twamp-client", "twamp-server" ] unless $conf{package_names};

    $self->SUPER::init( %conf );
    
    return 0;
}

sub get_addresses {
    my ($self) = @_;

    my @interfaces = $self->lookup_interfaces();

    my @addresses = ();
    foreach my $address (@interfaces) {
        $address = "[".$address."]" if is_ipv6($address);

        push @addresses, "tcp://".$address.":862";
    }

    return \@addresses;
}

1;
