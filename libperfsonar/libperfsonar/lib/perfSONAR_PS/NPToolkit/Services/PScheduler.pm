package perfSONAR_PS::NPToolkit::Services::PScheduler;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::NetworkBase';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "pScheduler" unless $conf{description};
    $conf{pid_files} = [ 
                            "/var/run/pscheduler-server/archiver/pid",
                            "/var/run/pscheduler-server/runner/pid",
                            "/var/run/pscheduler-server/scheduler/pid",
                            "/var/run/pscheduler-server/ticker/pid"
                        ] unless $conf{pid_files};
    #one for each pid
    $conf{process_names} = [ "python", "python", "python", "python" ] unless $conf{process_names};
    #Note pscheduler is more than one script, but this will indicate if enabled
    $conf{init_script} = 'pscheduler-scheduler' unless $conf{init_script};
    $conf{systemd_services} = ['pscheduler-scheduler', 'pscheduler-archiver', 'pscheduler-ticker', 'pscheduler-runner'];
    $conf{package_names} = [ "pscheduler-server" ] unless $conf{package_names};

    $self->SUPER::init( %conf );
    $self->{REGULAR_RESTART} = 0;
    
    return 0;
}

sub get_addresses {
    my ($self) = @_;

    my @interfaces = $self->lookup_interfaces();

    my @addresses = ();
    foreach my $address (@interfaces) {
        push @addresses, "https://".$address."/pscheduler";
    }

    return \@addresses;
}


1;
