package perfSONAR_PS::NPToolkit::Services::NPAD;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::NetworkBase';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "NPAD" unless $conf{description};
    $conf{process_names} = [ "DiagServer" ] unless $conf{process_names};
    $conf{pid_files} = [ "/var/run/npad.pid" ] unless $conf{pid_files};
    $conf{init_script} = "npad" unless $conf{init_script};
    $conf{can_disable} = 1;

    $self->SUPER::init( %conf );

    return 0;
}

sub get_addresses {
    my ($self) = @_;

    my @interfaces = $self->lookup_interfaces();

    my @addresses = ();
    foreach my $address (@interfaces) {
        push @addresses, "http://".$address.":8000/";
        push @addresses, "tcp://".$address.":8001";
    }

    return \@addresses;
}

# Try to stop gracefully, and if not, kill the NPAD process
sub kill {
	my ($self) = @_;

	my ($status, $res) = $self->SUPER::kill();

	if ($status != 0) {
		system("pkill -9 -f DiagServer");
	}

	return (0, "");
}

1;
