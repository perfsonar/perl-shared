package perfSONAR_PS::NPToolkit::Services::Base;

use strict;
use warnings;

use Log::Log4perl qw(:easy);
use File::Spec;
use fields 'LOGGER', 'INIT_SCRIPT', 'PID_FILES', 'PROCESS_NAMES', 'DESCRIPTION', 'CAN_DISABLE', 'REGULAR_RESTART', 'PACKAGE_NAMES';
use RPM2;

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
            open( PIDFILE, $pid_file ) or return;
            my $p_id = <PIDFILE>;
            close( PIDFILE );

            chomp( $p_id ) if ( defined $p_id );
            if ( $p_id ) {
		my $running = 0;
		open( PSVIEW, "-|", "ps ww -p " . $p_id );
		while ( <PSVIEW> ) {
		    if (/$self->{PROCESS_NAMES}[$i]/) {
			$running = 1;
                    }
		}
                close( PSVIEW );
		unless ( $? == 0 and $running ) {
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
    my $runlevel_output = `/sbin/runlevel`;
    if ( $? == 0 ) {
        if ($runlevel_output =~ /[N0-9] (\d)/) {
            $curr_runlevel = $1;
        }
    }

    return 1 unless $curr_runlevel;

    my $disabled = 1;

    # turn off stderr
    open(my $stderr, ">&STDERR");
    open(STDERR, ">", File::Spec->devnull());

    my $chkconfig_output = `/sbin/chkconfig --list $self->{INIT_SCRIPT}`;    

    # restore stderr
    open(STDERR, ">&", $stderr);

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

    # turn off stderr + stdout
    open(my $stderr, ">&STDERR");
    open(my $stdout, ">&STDOUT");
    open(STDERR, ">", File::Spec->devnull());
    open(STDOUT, ">", File::Spec->devnull());

    system( "/sbin/chkconfig --del  " . $self->{INIT_SCRIPT} );

    my $ret = system( "/sbin/chkconfig --add  " . $self->{INIT_SCRIPT} );

    # restore stderr + stdout
    open(STDERR, ">&", $stderr);
    open(STDOUT, ">&", $stdout);

    return $ret;
}

sub disable_startup {
    my ($self) = @_;

    unless ($self->{INIT_SCRIPT}) {
	$self->{LOGGER}->error("No init script specified for this service");
	return -1;
    }

    # turn off stderr + stdout
    open(my $stderr, ">&STDERR");
    open(my $stdout, ">&STDOUT");
    open(STDERR, ">", File::Spec->devnull());
    open(STDOUT, ">", File::Spec->devnull());

    my $ret = system( "/sbin/chkconfig --del " . $self->{INIT_SCRIPT});

    # restore stderr + stdout
    open(STDERR, ">&", $stderr);
    open(STDOUT, ">&", $stdout);

    return $ret;
}

sub run_init {
    my ($self, $cmd) = @_;

    unless ($self->{INIT_SCRIPT}) {
	$self->{LOGGER}->error("No init script specified for this service");
	return -1;
    }

    # turn off stderr + stdout
    open(my $stderr, ">&STDERR");
    open(my $stdout, ">&STDOUT");
    open(STDERR, ">", File::Spec->devnull());
    open(STDOUT, ">", File::Spec->devnull());

    my $shell_cmd = "/sbin/service " . $self->{INIT_SCRIPT} . " " . $cmd;

    $self->{LOGGER}->debug($shell_cmd);

    my $ret = system( $shell_cmd );

    # restore stderr + stdout
    open(STDERR, ">&", $stderr);
    open(STDOUT, ">&", $stdout);

    return $ret;
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
