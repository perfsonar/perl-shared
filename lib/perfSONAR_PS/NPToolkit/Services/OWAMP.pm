package perfSONAR_PS::NPToolkit::Services::OWAMP;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::NetworkBase';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "OWAMP" unless $conf{description};
    $conf{process_names} = [ "owampd" ] unless $conf{process_names};
    $conf{pid_files} = [ "/var/run/owampd.pid" ] unless $conf{pid_files};
    $conf{init_script} = "owampd" unless $conf{init_script};
    $conf{can_disable} = 1;

    $self->SUPER::init( %conf );

    return 0;
}

sub get_addresses {
    my ($self) = @_;

    my @interfaces = $self->lookup_interfaces();

    my @addresses = ();
    foreach my $address (@interfaces) {
        push @addresses, "tcp://".$address.":861";
    }

    return \@addresses;
}

# Try to stop gracefully, and if not, kill the owampd processes
sub kill {
	my ($self) = @_;

	my ($status, $res) = $self->SUPER::kill();

	if ($status != 0) {
		system("pkill -9 -f owampd");
	}

	return (0, "");
}

1;
