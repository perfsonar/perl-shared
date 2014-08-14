package perfSONAR_PS::NPToolkit::Services::Base;

use strict;
use warnings;

use Log::Log4perl qw(:easy);
use RPM2;

use fields 'LOGGER', 'INIT_SCRIPT', 'PID_FILES', 'PROCESS_NAMES', 'DESCRIPTION', 'CAN_DISABLE', 'REGULAR_RESTART', 'PACKAGE_NAMES';

sub new {
    my ( $package ) = @_;

    my $self = fields::new( $package );
    $self->{LOGGER} = get_logger( $package );
    $self->{REGULAR_RESTART} = 0;

    return $self;
}

sub init {
    my $self   = shift;
    my %params = @_;

    $self->{DESCRIPTION}  = $params{description};
    $self->{INIT_SCRIPT}  = $params{init_script};
    $self->{CAN_DISABLE}  = $params{can_disable};

    if ( $params{pid_files} and ref( $params{pid_files} ) ne "ARRAY" ) {
        $params{pid_files} = [ $params{pid_files} ];
    }
    $self->{PID_FILES} = $params{pid_files};

    if ( ref( $params{process_names} ) ne "ARRAY" ) {
        $params{process_names} = [ $params{process_names} ];
    }
    $self->{PROCESS_NAMES} = $params{process_names};

    if ( $params{package_names} and ref( $params{package_names} ) ne "ARRAY" ) {
        $params{package_names} = [ $params{package_names} ];
    }
    $self->{PACKAGE_NAMES} = $params{package_names};

    return 0;
}

sub package_version {
    my ($self) = @_;

    my $version;
    if ($self->{PACKAGE_NAMES}) {
        my $min;

        if (my $db = RPM2->open_rpm_db()) {
            foreach my $package_name (@{ $self->{PACKAGE_NAMES} }) {
                my @packages = $db->find_by_name($package_name);
    
                foreach my $package (@packages) {
                    $min = $package unless $min;
    
                    my $result = ($package <=> $min);
                    if ($result < 0) {
                        $min = $package;
                    }
                }
            }
        }

        $version = $min->version."-".$min->release if $min;
    }

    return $version;
}

sub needs_regular_restart {
    my ($self) = @_;
    # Defaults to 'no'
 
    return $self->{REGULAR_RESTART};
}

sub check_running {
    my ($self) = @_;

    unless ($self->{PID_FILES}) {
        foreach my $pname ( @{ $self->{PROCESS_NAMES} } ) {
            my $results = `pgrep -f $pname`;
            chomp($results);
            return unless ($results);
        }
    }
    else {
        my $i = 0;
        foreach my $pid_file ( @{ $self->{PID_FILES} } ) {
            open( PIDFILE, $pid_file ) or return (-1, "Couldn't open $pid_file");
            my $p_id = <PIDFILE>;
            close( PIDFILE );

            chomp( $p_id ) if ( defined $p_id );
            if ( $p_id ) {
                open( PSVIEW, "ps -p " . $p_id . " | grep " . $self->{PROCESS_NAMES}[$i] . " |" );
                my @output = <PSVIEW>;
                close( PSVIEW );
                if ( $? != 0 ) {
                    return;
                }
            }
            else {
                return;
            }

            $i++;
        }
    }

    return 1;
}

sub name {
    my ($self) = @_;

    return $self->{DESCRIPTION};
}

sub can_disable {
    my ($self) = @_;

    return $self->{CAN_DISABLE};
}

sub disabled {
    my ($self) = @_;

    # Check if the service is "on" in this run level.

    unless ($self->{INIT_SCRIPT}) {
	$self->{LOGGER}->error("No init script specified for this service");
	return -1;
    }

    my $curr_runlevel;
    my $runlevel_output = `runlevel`;
    if ( $? == 0 ) {
        if ($runlevel_output =~ /[N0-9] (\d)/) {
            $curr_runlevel = $1;
        }
    }

    return 1 unless $curr_runlevel;

    my $disabled = 1;

    my $chkconfig_output = `chkconfig --list $self->{INIT_SCRIPT} 2> /dev/null`;
    foreach my $line (split('\n', $chkconfig_output)) {
        $disabled = 0 if ($line =~ /$curr_runlevel:on/);
    }

    return $disabled;
}

sub enable_startup {
    my ($self) = @_;

    unless ($self->{INIT_SCRIPT}) {
	$self->{LOGGER}->error("No init script specified for this service");
	return -1;
    }

    return system( "chkconfig --add  " . $self->{INIT_SCRIPT} . " &> /dev/null" );
}

sub disable_startup {
    my ($self) = @_;

    unless ($self->{INIT_SCRIPT}) {
	$self->{LOGGER}->error("No init script specified for this service");
	return -1;
    }

    return system( "chkconfig --del " . $self->{INIT_SCRIPT} . " &> /dev/null");
}

sub run_init {
    my ($self, $cmd) = @_;

    unless ($self->{INIT_SCRIPT}) {
	$self->{LOGGER}->error("No init script specified for this service");
	return -1;
    }

    my $shell_cmd = "service " . $self->{INIT_SCRIPT} . " " . $cmd . "&> /dev/null";

    $self->{LOGGER}->debug($shell_cmd);

    return system( $shell_cmd );
}

sub start {
    my ($self) = @_;

    return $self->run_init( "start" );
}

sub restart {
    my ($self) = @_;

    return $self->run_init( "restart" );
}

sub kill {
    my ($self) = @_;

    return $self->run_init( "stop" );
}

1;
