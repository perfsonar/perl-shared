package perfSONAR_PS::NPToolkit::Services::RegularTesting;

use strict;
use warnings;

use base 'perfSONAR_PS::NPToolkit::Services::Base';

sub init {
    my ( $self, %conf ) = @_;

    $conf{description}  = "perfSONAR Regular Testing" unless $conf{description};
    $conf{pid_files} = [ "/var/run/regulartesting.pid" ] unless $conf{pid_files};
    #'ps -p' only prints first 15 characters, so use shortened process name
    $conf{process_names} = [ "perfSONAR Regular Testing" ] unless $conf{process_names};
    $conf{init_script} = "perfsonar-regulartesting" unless $conf{init_script};
    $conf{package_names} = [ "perfsonar-regulartesting" ] unless $conf{package_names};

    $self->SUPER::init( %conf );
    $self->{REGULAR_RESTART} = 1;
    
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
	system('pkill -9 -f regulartesting/');
	
	#clean-up any data older than 5 minutes
	system('find /var/lib/perfsonar/regulartesting -type f -mmin +5 -exec rm {} \;');
	#delete empty directories
	system('find /var/lib/perfsonar/regulartesting/ -type d -empty -delete'); 
    
	return (0, "");
}

1;
