package perfSONAR_PS::NPToolkit::Services::SimpleLSBootstrap;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "Simple LS Boostrap Client" unless $conf{description};
    $conf{process_names} = "SimpleLSBoot" unless $conf{process_names};
    $conf{pid_files} = "/var/run/SimpleLSBootStrapClientDaemon.pid" unless $conf{pid_files};
    $conf{init_script} = "simple_ls_bootstrap_client" unless $conf{init_script};

    $self->SUPER::init( %conf );

    return 0;
}

1;
