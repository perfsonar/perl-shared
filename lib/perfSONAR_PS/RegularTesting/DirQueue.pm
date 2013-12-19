package perfSONAR_PS::RegularTesting::DirQueue;

use strict;
use warnings;

our $VERSION = 3.4;

use base 'IPC::DirQueue';
use Log::Log4perl qw(get_logger);

my $logger = get_logger(__PACKAGE__);

sub queue_iter_next {
  my ($self, $iter) = @_;

  my $fname = $self->SUPER::queue_iter_next($iter);

  return unless $fname;

  ($fname) = ($fname =~ /(.*)/);

  $logger->debug("queue_iter_next(): $fname");
  return $fname;
}

sub read_control_file {
  my ($self, $job, $infh) = @_;

  $job = $self->SUPER::read_control_file($job, $infh);

  return unless $job;

  foreach my $key (keys %$job) {
    next if ref($job->{$key});

    ($job->{$key}) = ($job->{$key} =~ /(.*)/s);
  }

  return $job;
}

1;
