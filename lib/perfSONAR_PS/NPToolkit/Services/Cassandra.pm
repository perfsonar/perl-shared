package perfSONAR_PS::NPToolkit::Services::Cassandra;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "Cassandra Database" unless $conf{description};
    $conf{init_script} = "cassandra" unless $conf{init_script};
    #switch below to java if uncomment pid files
    $conf{process_names} = "cassandra" unless $conf{process_names};
    #Cassandra does not properly create /var/run/cassandra directory on boot, only creates
    #  on install which then gets removed on reboot. Removing this for now.
    #$conf{pid_files} = "/var/run/cassandra/cassandra.pid" unless $conf{pid_files};
    $conf{package_names} = [ "cassandra20" ] unless $conf{package_names};

    $self->SUPER::init( %conf );

    return 0;
}

1;
