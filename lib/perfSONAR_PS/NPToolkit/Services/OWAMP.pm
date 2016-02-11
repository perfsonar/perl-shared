package perfSONAR_PS::NPToolkit::Services::OWAMP;

use strict;
use warnings;

use Data::Validate::IP qw(is_ipv6);

use base 'perfSONAR_PS::NPToolkit::Services::NetworkBase';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "OWAMP" unless $conf{description};
    $conf{process_names} = [ "owampd" ] unless $conf{process_names};
    $conf{pid_files} = [ "/var/run/owamp-server.pid" ] unless $conf{pid_files};
    $conf{init_script} = "owamp-server" unless $conf{init_script};
    $conf{can_disable} = 1;
    $conf{package_names} = [ "owamp-client", "owamp-server" ] unless $conf{package_names};

    $self->SUPER::init( %conf );
    $self->{REGULAR_RESTART} = 1;
    
    return 0;
}

sub get_addresses {
    my ($self) = @_;

    my @interfaces = $self->lookup_interfaces();

    my @addresses = ();
    foreach my $address (@interfaces) {
        $address = "[".$address."]" if is_ipv6($address);

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
	}else{
	    sleep(30);
	    system("pkill -9 -f owampd");
	}
    
	system('find /var/lib/owamp -type f -mtime +1 -exec rm {} \;');
    
	return (0, "");
}

1;
