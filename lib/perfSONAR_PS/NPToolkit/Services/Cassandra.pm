package perfSONAR_PS::NPToolkit::Services::Cassandra;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "Cassandra Database" unless $conf{description};
    $conf{init_script} = "cassandra" unless $conf{init_script};
    $conf{process_names} = "java" unless $conf{process_names};
    $conf{pid_files} = "/var/run/cassandra/cassandra.pid" unless $conf{pid_files};
    $conf{package_names} = [ "cassandra20" ] unless $conf{package_names};

    $self->SUPER::init( %conf );

    return 0;
}

1;
