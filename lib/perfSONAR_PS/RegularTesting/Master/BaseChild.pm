package perfSONAR_PS::RegularTesting::Master::BaseChild;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use perfSONAR_PS::RegularTesting::Config;

use Moose;

has 'pid'     => (is => 'rw', isa => 'Int');
has 'config'  => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Config');
has 'exiting' => (is => 'rw', isa => 'Bool');

my $logger = get_logger(__PACKAGE__);

sub run {
    my ($self) = @_;

    my $pid = fork();
    if ($pid) {
        $self->pid($pid);
        return $pid;
    }

    $self->child_initialize_signals();

    $self->child_main_loop();

    exit(0);

    return;
}

sub kill_child {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { force => 0 });
    my $force = $parameters->{force};

    return unless $self->pid;

    if ($force) {
        kill('KILL', $self->pid);
    }
    else {
        kill('TERM', $self->pid);
    }

    return;
}

sub child_initialize_signals {
    my ($self) = @_;

    $SIG{CHLD} = 'IGNORE';

    $SIG{TERM} = $SIG{INT} = sub {
        $self->exiting(1);
        $self->handle_exit();
    };

    return;
}

sub child_main_loop {
    my ($self) = @_;

    die("'child_main_loop' needs to be overridden");
}

sub handle_exit {
    my ($self) = @_;

    exit(0);
}

1;
