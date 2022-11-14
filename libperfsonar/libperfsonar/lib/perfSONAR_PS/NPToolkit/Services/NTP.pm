package perfSONAR_PS::NPToolkit::Services::NTP;

use strict;
use warnings;

use Net::NTP;
use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{init_script} = "ntpd" unless $conf{init_script};
    $conf{description}  = "NTP" unless $conf{description};
    $conf{process_names} = "ntpd" unless $conf{process_names};
    $conf{pid_files} = "/var/run/ntpd.pid" unless $conf{pid_files};
    $conf{package_names} = [ "ntp" ] unless $conf{package_names};

    $self->SUPER::init( %conf );

    return 0;
}

sub is_synced {
    my %response;
    eval {
        %response = get_ntp_response("localhost");
    };
    return if ($@);

    return ($response{'Reference Clock Identifier'} and $response{'Reference Clock Identifier'} ne "INIT");
}

1;
