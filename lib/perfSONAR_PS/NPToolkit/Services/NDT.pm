package perfSONAR_PS::NPToolkit::Services::NDT;

use strict;
use warnings;

use Data::Validate::IP qw(is_ipv6);

use base 'perfSONAR_PS::NPToolkit::Services::NetworkBase';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "NDT" unless $conf{description};
    $conf{process_names} = [ "web100srv", "fakewww" ] unless $conf{process_names};
    $conf{init_script} = "ndt" unless $conf{init_script};
    $conf{can_disable} = 1;
    $conf{package_names} = [ "ndt-client", "ndt-server" ] unless $conf{package_names};

    $self->SUPER::init( %conf );

    return 0;
}

sub get_addresses {
    my ($self) = @_;

    my @interfaces = $self->lookup_interfaces();

    my @addresses = ();
    foreach my $address (@interfaces) {
        $address = "[".$address."]" if is_ipv6($address);

        push @addresses, "http://".$address.":7123/";
        push @addresses, "tcp://".$address.":3001";
    }

    return \@addresses;
}

# Try to stop gracefully, and if not, kill the NDT process
sub kill {
	my ($self) = @_;

	my ($status, $res) = $self->SUPER::kill();

	if ($status != 0) {
		system("pkill -9 -f web100srv");
		system("pkill -9 -f fakewww");
	}

	return (0, "");
}

sub is_installed{
    my ($self) = @_;
    my $response = `rpm -qi ndt`;

    my $substr = 'not installed';

    if(index($response, $substr) == -1){
        #installed
        return 1;
    }
    return 0; 
}

1;
