package perfSONAR_PS::NPToolkit::Services::BWCTL;

use strict;
use warnings;

use Data::Validate::IP qw(is_ipv6);

use base 'perfSONAR_PS::NPToolkit::Services::NetworkBase';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "BWCTL" unless $conf{description};
    $conf{init_script} = "bwctl-server" unless $conf{init_script};
    $conf{process_names} = "bwctld" unless $conf{process_names};
    $conf{pid_files} = "/var/run/bwctl-server.pid" unless $conf{pid_files};
    $conf{package_names} = [ "bwctl-server", "bwctl-client" ] unless $conf{package_names};
    $conf{regular_restart} = 1;
    $conf{can_disable} = 1;

    $self->SUPER::init( %conf );

    return 0;
}

sub get_addresses {
    my ($self) = @_;

    my @interfaces = $self->lookup_interfaces();

    my @addresses = ();
    foreach my $address (@interfaces) {
        $address = "[".$address."]" if is_ipv6($address);

        push @addresses, "tcp://".$address.":4823";
    }

    return \@addresses;
}

# Try to stop gracefully, and if not, kill the bwctld processes
sub kill {
	my ($self) = @_;

	my ($status, $res) = $self->SUPER::kill();

	if ($status != 0) {
		system("pkill -9 -f bwctld");
	}

	return (0, "");
}

1;
