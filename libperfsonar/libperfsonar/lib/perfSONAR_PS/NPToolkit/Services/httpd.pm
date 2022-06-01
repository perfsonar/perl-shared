package perfSONAR_PS::NPToolkit::Services::httpd;

use strict;
use warnings;

use Data::Validate::IP qw(is_ipv6);

use base 'perfSONAR_PS::NPToolkit::Services::NetworkBase';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "Apache HTTP Server" unless $conf{description};
    $conf{init_script} = "httpd" unless $conf{init_script};
    $conf{process_names} = "httpd" unless $conf{process_names};
    $conf{pid_files} = "/var/run/httpd/httpd.pid" unless $conf{pid_files};
    $conf{package_names} = [ "httpd" ] unless $conf{package_names};

    $self->SUPER::init( %conf );

    return 0;
}

sub get_addresses {
    my ($self) = @_;

    my @interfaces = $self->lookup_interfaces();

    my @addresses = ();
    foreach my $address (@interfaces) {
        $address = "[".$address."]" if is_ipv6($address);

        push @addresses, "http://".$address."/";
    }

    return \@addresses;
}

sub restart {
    my ($self) = @_;

    return run_init( "reload" );
}

1;
