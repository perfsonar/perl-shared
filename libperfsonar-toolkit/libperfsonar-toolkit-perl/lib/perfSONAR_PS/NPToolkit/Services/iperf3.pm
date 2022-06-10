package perfSONAR_PS::NPToolkit::Services::iperf3;

use strict;
use warnings;

use Data::Validate::IP qw(is_ipv6);

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "iperf3" unless $conf{description};
    $conf{init_script} = "" unless $conf{init_script};
    $conf{process_names} = "iperf3" unless $conf{process_names};
    $conf{pid_files} = "" unless $conf{pid_files};
    $conf{package_names} = [ "iperf3" ] unless $conf{package_names};
    $conf{regular_restart} = 0;
    $conf{can_disable} = 0;

    $self->SUPER::init( %conf );

    return 0;
}

1;
