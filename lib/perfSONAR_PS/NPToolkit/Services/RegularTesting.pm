package perfSONAR_PS::NPToolkit::Services::RegularTesting;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "perfSONAR-PS Regular Testing" unless $conf{description};
    $conf{pid_files} = [ "/var/run/regular_testing.pid" ] unless $conf{pid_files};
    $conf{process_names} = [ "daemon" ] unless $conf{process_names};
    $conf{init_script} = "regular_testing" unless $conf{init_script};
    $conf{package_names} = [ "perl-perfSONAR_PS-RegularTesting" ] unless $conf{package_names};

    $self->SUPER::init( %conf );

    return 0;
}

sub kill {
	my ($self) = @_;

	my ($status, $res) = $self->SUPER::kill();

	sleep(10);

	if ($status != 0) {
		system("pkill -9 -f Regular");
	}
    
    #No matter what, clean-up stray children
    system('pkill -9 -f regular_testing/');
    
    #clean-up any old data
    system('find /var/lib/perfsonar/regular_testing -type f -mtime +7 -exec rm {} \;');
    
	return (0, "");
}

sub needs_regular_restart {
	my ($self) = @_;

	return 0;
}

1;
