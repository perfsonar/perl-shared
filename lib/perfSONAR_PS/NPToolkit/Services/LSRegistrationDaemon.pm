package perfSONAR_PS::NPToolkit::Services::LSRegistrationDaemon;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "LS Registration Daemon" unless $conf{description};
    $conf{init_script} = "ls_registration_daemon" unless $conf{init_script};
    $conf{pid_files} = "/var/run/ls_registration_daemon.pid";
    $conf{process_names} = "daemon.pl";

    $self->SUPER::init( %conf );

    return 0;
}

1;
