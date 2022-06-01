package perfSONAR_PS::NPToolkit::Services::LSCacheDaemon;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "LS Cache Daemon" unless $conf{description};
    $conf{init_script} = "perfsonar-lscachedaemon" unless $conf{init_script};
    $conf{pid_files} = "/var/run/lscachedaemon.pid" unless $conf{pid_files};
    $conf{process_names} = "lscachedaemon.pl" unless $conf{process_names};
    $conf{package_names} = [ "perfsonar-lscachedaemon" ] unless $conf{package_names};

    return $self->SUPER::init( %conf );
}

1;
