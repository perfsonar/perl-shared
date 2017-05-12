package perfSONAR_PS::NPToolkit::Services::MeshConfigAgent;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "perfSONAR MeshConfig Agent" unless $conf{description};
    $conf{pid_files} = [ "/var/run/perfsonar-meshconfig-agent.pid" ] unless $conf{pid_files};
    #'ps -p' only prints first 15 characters, so use shortened process name
    $conf{process_names} = [ "perfsonar_meshconfig_agent.pl" ] unless $conf{process_names};
    $conf{init_script} = "perfsonar-meshconfig-agent" unless $conf{init_script};
    $conf{package_names} = [ "perfsonar-meshconfig-agent" ] unless $conf{package_names};

    $self->SUPER::init( %conf );
    $self->{REGULAR_RESTART} = 0;
    
    return 0;
}

1;
