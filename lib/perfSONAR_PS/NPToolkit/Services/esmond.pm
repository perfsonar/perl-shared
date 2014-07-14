package perfSONAR_PS::NPToolkit::Services::esmond;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::httpd';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "esmond Measurement Archive" unless $conf{description};
    $conf{package_names} = [ "esmond" ] unless $conf{package_names};

    $self->SUPER::init( %conf );

    return 0;
}

sub get_addresses {
    my ($self) = @_;

    my @interfaces = $self->lookup_interfaces();

    my @addresses = ();
    foreach my $address (@interfaces) {
        push @addresses, "http://".$address."/esmond/perfsonar/archive/";
    }

    return \@addresses;
}

1;
