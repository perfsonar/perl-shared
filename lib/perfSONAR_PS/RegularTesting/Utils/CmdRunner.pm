package perfSONAR_PS::RegularTesting::Utils::CmdRunner;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use IO::Select;
use POSIX;

use perfSONAR_PS::RegularTesting::Utils::CmdRunner;

use Moose;

has 'cmds' => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::RegularTesting::Utils::CmdRunner::Cmd]');

has 'cmds_not_run' => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::RegularTesting::Utils::CmdRunner::Cmd]');

has 'exiting' => (is => 'rw', isa => 'Bool');

my $logger = get_logger(__PACKAGE__);

sub init {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { cmds => 1 });
    my $cmds = $parameters->{cmds};

    $self->cmds($cmds);
    $self->cmds_not_run($cmds);

    return (0, "");
}

sub run {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { });

    local $SIG{CHLD} = 'DEFAULT';

    my $select = IO::Select->new();

    while (1) {
        last if $self->exiting;

        my @remaining_cmds = ();

        foreach my $cmd (@{ $self->cmds_not_run }) {
            unless (not $cmd->last_exec_time or ($cmd->restart_interval and $cmd->restart_interval + $cmd->last_exec_time < time)) {
                push @remaining_cmds, $cmd;
                next;
            }

	    last if $self->exiting;

            $logger->debug("Running command: ".$cmd->cmd_str);

            my ($status, $res) = $cmd->exec();
            if ($status != 0) {
                my $msg = "Problem executing command: $res";
                $logger->error($msg);
                next;
            }

            $select->add($cmd->stdout_fh);
            $select->add($cmd->stderr_fh);
        }

        $self->cmds_not_run(\@remaining_cmds);

        last if $self->exiting;

        # Special case: no commands are running, so select will return immediately
        if (scalar(@{ $self->cmds_not_run }) == scalar(@{ $self->cmds })) {
            sleep(1);
            next;
        }

        my @ready = $select->can_read(5);

        last if $self->exiting;

        foreach my $fh (@ready) {
            my ($cmd_fh, $direction);

            # Find the matching command
            foreach my $cmd (@{ $self->cmds }) {
                if ($cmd->stdout_fh and $cmd->stdout_fh == $fh) {
                    $direction = "stdout";
                    $cmd_fh = $cmd;
                    last;
                }
                elsif ($cmd->stderr_fh and $cmd->stderr_fh == $fh) {
                    $direction = "stderr";
                    $cmd_fh = $cmd;
                    last;
                }
            }

	    # If we can't file a matching command, remove it from the select.
            unless ($cmd_fh) {
                $select->remove($fh);
                next;
            }

            while(my $res = $fh->sysread(my $buf, 5)) {
                next unless $cmd_fh->result_cb;

                if ($direction eq "stdout") {
                    if ($cmd_fh->stdout_prev_line) {
                        $buf = $cmd_fh->stdout_prev_line.$buf;
                        $cmd_fh->stdout_prev_line("");
                    }
                }
                elsif ($direction eq "stderr") {
                    if ($cmd_fh->stderr_prev_line) {
                        $buf = $cmd_fh->stderr_prev_line.$buf;
                        $cmd_fh->stderr_prev_line("");
                    }
                }

                my $complete_lines;
                if ($buf =~ /\n$/) {
                    $complete_lines = 1;
                }

                my @lines = split(/\n/, $buf);

                my $incomplete_line = "";

                unless ($complete_lines) {
                    $incomplete_line = pop(@lines);
                }

                if ($direction eq "stdout") {
                    $cmd_fh->stdout_prev_line($incomplete_line);
                }
                elsif ($direction eq "stderr") {
                    $cmd_fh->stderr_prev_line($incomplete_line);
                }

                next unless (scalar(@lines) > 0);

                eval {
                    ($cmd_fh->result_cb)->($cmd_fh, { $direction => \@lines });
                };
                if ($@) {
                    $logger->error("Problem with results callback: $@");
                }
            }
 
	    # Remove closed file handles so we don't keep selecting on them
            unless ($! == EAGAIN) {
                $select->remove($fh);
                next;
            }
        }

        last if $self->exiting;

        while( ( my $pid = waitpid( -1, &WNOHANG ) ) > 0 ) {
            last if $self->exiting;

            foreach my $cmd (@{ $self->cmds }) {
                next unless ($cmd->pid and $cmd->pid == $pid);

                unless ($self->exiting) {
                    my $remaining_seconds = ($cmd->restart_interval + $cmd->last_exec_time) - time;

                    $logger->error("Command exited, will restart in ".$remaining_seconds." seconds: ".$cmd);
                }

                $select->remove($cmd->stdout_fh) if $cmd->stdout_fh;
                $select->remove($cmd->stderr_fh) if $cmd->stderr_fh;

                close($cmd->stderr_fh) if $cmd->stderr_fh;

                $cmd->pid(undef);

                close($cmd->stdin_fh) if $cmd->stdin_fh;
                close($cmd->stdout_fh) if $cmd->stdout_fh;
                close($cmd->stderr_fh) if $cmd->stderr_fh;

                if ($cmd->exit_cb) {
                    ($cmd->exit_cb)->($cmd);
                }

                push @{ $self->cmds_not_run }, $cmd;

                last;
            }
        }
   }

   $logger->debug("run() exited");
}

sub stop {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { });

    $self->exiting(1);

    foreach my $cmd (@{ $self->cmds }) {
        $cmd->kill();
    }

    # Wait two seconds for processes to exit
    my $waketime = time + 2;
    while ((my $sleep_time = $waketime - time) > 0) {
        sleep($sleep_time);
    }

    while( ( my $pid = waitpid( -1, &WNOHANG ) ) > 0 ) {
        foreach my $cmd (@{ $self->cmds }) {
            next unless $cmd->pid and $cmd->pid == $pid;

            $cmd->pid(undef);

            close($cmd->stdin_fh) if $cmd->stdin_fh;
            close($cmd->stdout_fh) if $cmd->stdout_fh;
            close($cmd->stderr_fh) if $cmd->stderr_fh;
        }
    }

    foreach my $cmd (@{ $self->cmds }) {
        $cmd->kill(force => 1);
    }

    return;
}

1;
