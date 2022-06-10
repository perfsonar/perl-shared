package perfSONAR_PS::NPToolkit::Services::ConfigDaemon;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "perfSONAR Configuration Daemon" unless $conf{description};
    $conf{init_script} = "perfsonar-configdaemon" unless $conf{init_script};
    $conf{process_names} = "config_daemon" unless $conf{process_names};
    $conf{pid_files} = "/var/run/configdaemon.pid" unless $conf{pid_files};
    $conf{package_names} = [ "perfsonar-toolkit" ] unless $conf{package_names};

    $self->SUPER::init( %conf );

    return 0;
}

1;
