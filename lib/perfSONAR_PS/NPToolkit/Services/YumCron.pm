package perfSONAR_PS::NPToolkit::Services::YumCron;

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

    my $ret = system( "chkconfig --add  " . $self->{INIT_SCRIPT} );
    #need to run chkconfig on
    $ret = system( "chkconfig " . $self->{INIT_SCRIPT} . " on");
    
    # restore stderr + stdout
    open(STDERR, ">&", $stderr);
    open(STDOUT, ">&", $stdout);

    return $ret;
}

1;
