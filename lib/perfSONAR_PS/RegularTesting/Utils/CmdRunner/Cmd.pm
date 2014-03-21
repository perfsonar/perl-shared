package perfSONAR_PS::RegularTesting::Utils::CmdRunner::Cmd;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use IPC::Open3;
use Symbol;

use Moose;

my $logger = get_logger(__PACKAGE__);

has 'cmd'              => (is => 'rw', isa => 'ArrayRef[Str]');
has 'result_cb'        => (is => 'rw', isa => 'CodeRef');
has 'restart_interval' => (is => 'rw', isa => 'Int');
has 'exit_cb'          => (is => 'rw', isa => 'CodeRef');

has 'private'          => (is => 'rw', isa => 'Any|Undef');

has 'pid'              => (is => 'rw', isa => 'Int|Undef');
has 'stdin_fh'         => (is => 'rw', isa => 'FileHandle|Undef');
has 'stderr_fh'        => (is => 'rw', isa => 'FileHandle|Undef');
has 'stdout_fh'        => (is => 'rw', isa => 'FileHandle|Undef');

has 'stdout_prev_line'  => (is => 'rw', isa => 'Str');
has 'stderr_prev_line'  => (is => 'rw', isa => 'Str');

has 'last_exec_time'   => (is => 'rw', isa => 'Int');

sub cmd_str {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { });

    return join(" ", @{ $self->cmd });
}

sub exec {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { });

    $self->last_exec_time(time);

    my ($pid,$infh,$outfh,$errfh);

    $errfh = gensym();

    eval {
        $pid = open3($infh, $outfh, $errfh, @{ $self->cmd });
        $outfh->blocking(0);
        $errfh->blocking(0);
    };
    if ($@) {
        my $msg = "Problem executing command: $@";
        $logger->error($msg);
        return (-1, $msg);
    }

    $self->pid($pid);
    $self->stdin_fh($infh);
    $self->stdout_fh($outfh);
    $self->stderr_fh($errfh);

    $self->stdout_prev_line("");
    $self->stderr_prev_line("");

    return (0, "");
}

sub kill {
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

1;
