package perfSONAR_PS::RegularTesting::EventQueue::Queue;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use Digest::MD5;
use Data::UUID;

use Moose;

has 'events' => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::RegularTesting::EventQueue::Event]', default => sub { [] });

my $logger = get_logger(__PACKAGE__);

sub pop {
    my ($self) = @_;

    return pop(@{ $self->events });
}

sub insert {
    my ($self, $event) = @_;

    my $i;
    for($i = 0; $self->events->[$i] && $self->events->[$i]->time <= $event->time; $i++) {
       ;
    }

    splice @{ $self->events }, $i, 0, $event;

    return;
}

1;
