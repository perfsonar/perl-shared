package perfSONAR_PS::NPToolkit::Services::LSRegistrationDaemon;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "LS Registration Daemon" unless $conf{description};
    $conf{init_script} = "perfsonar-lsregistrationdaemon" unless $conf{init_script};
    $conf{pid_files} = "/var/run/lsregistrationdaemon.pid";
    $conf{process_names} = "lsregistrationdaemon.pl";
    $conf{package_names} = [ "perfsonar-lsregistrationdaemon" ] unless $conf{package_names};

    $self->SUPER::init( %conf );

    return 0;
}

1;
