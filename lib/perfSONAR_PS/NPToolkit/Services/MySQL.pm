package perfSONAR_PS::NPToolkit::Services::MySQL;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "MySQL Daemon" unless $conf{description};
    $conf{init_script} = "mysqld" unless $conf{init_script};
    $conf{process_names} = [ "mysql" ] unless $conf{process_names};
    $conf{pid_files} = [ "/var/run/mysqld/mysqld.pid" ] unless $conf{pid_files};
    $conf{regular_restart} = 1;
    $conf{package_names} = [ "mysql-server" ] unless $conf{package_names};

    $self->SUPER::init( %conf );

    return 0;
}

1;
