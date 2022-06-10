package perfSONAR_PS::NPToolkit::Services::MaDDash;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "MaDDash perfSONAR Dashboard" unless $conf{description};
    $conf{init_script} = "maddash-server" unless $conf{init_script};
    $conf{process_names} = "java" unless $conf{process_names};
    $conf{pid_files} = "/var/run/cassandra/cassandra.pid" unless $conf{pid_files};
    $conf{can_disable} = 1;
    $conf{package_names} = [ "maddash-server", "maddash-webui" ] unless $conf{package_names};

    $self->SUPER::init( %conf );

    return 0;
}

1;
