package perfSONAR_PS::NPToolkit::Services::PSConfigPSchedulerAgent;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "PSConfig PScheduler Agent" unless $conf{description};
    $conf{pid_files} = [ "/var/run/psconfig-pscheduler-agent.pid" ] unless $conf{pid_files};
    #'ps -p' only prints first 15 characters, so use shortened process name
    $conf{process_names} = [ "psconfig_pscheduler_agent" ] unless $conf{process_names};
    $conf{init_script} = "psconfig-pscheduler-agent" unless $conf{init_script};
    $conf{package_names} = [ "perfsonar-psconfig-pscheduler" ] unless $conf{package_names};

    $self->SUPER::init( %conf );
    $self->{REGULAR_RESTART} = 0;
    
    return 0;
}

1;
