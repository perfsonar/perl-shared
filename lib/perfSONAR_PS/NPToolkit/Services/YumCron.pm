package perfSONAR_PS::NPToolkit::Services::Cassandra;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "Yum Automatic Updates" unless $conf{description};
    $conf{init_script} = "yum-cron" unless $conf{init_script};
    $conf{process_names} = "yum" unless $conf{process_names};
    $conf{pid_files} = "/var/lock/yum-cron.lock/pidfile" unless $conf{pid_files};
    $conf{package_names} = [ "yum-cron" ] unless $conf{package_names};

    $self->SUPER::init( %conf );

    return 0;
}

1;
