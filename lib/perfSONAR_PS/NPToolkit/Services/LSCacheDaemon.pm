package perfSONAR_PS::NPToolkit::Services::LSCacheDaemon;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "LS Cache Daemon" unless $conf{description};
    $conf{init_script} = "ls_cache_daemon" unless $conf{init_script};
    $conf{pid_files} = "/var/run/ls_cache_daemon.pid" unless $conf{pid_files};
    $conf{process_names} = "daemon.pl" unless $conf{process_names};
    $conf{package_names} = [ "perl-perfSONAR_PS-LSCacheDaemon" ] unless $conf{package_names};

    return $self->SUPER::init( %conf );
}

1;
