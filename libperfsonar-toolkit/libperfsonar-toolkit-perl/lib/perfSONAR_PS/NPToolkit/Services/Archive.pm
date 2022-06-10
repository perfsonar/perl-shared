package perfSONAR_PS::NPToolkit::Services::Archive;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::httpd';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "Measurement Archive" unless $conf{description};
    $conf{package_names} = [ "perfsonar-archive", "perfsonar-logstash", "perfsonar-elmond" ] unless $conf{package_names};

    $self->SUPER::init( %conf );

    return 0;
}

sub get_addresses {
    my ($self) = @_;

    my @interfaces = $self->lookup_interfaces();

    my @addresses = ();
    foreach my $address (@interfaces) {
        push @addresses, "https://".$address."/opensearch";
        push @addresses, "https://".$address."/logstash";
        push @addresses, "https://".$address."/esmond/perfsonar/archive/";
    }

    return \@addresses;
}

1;
