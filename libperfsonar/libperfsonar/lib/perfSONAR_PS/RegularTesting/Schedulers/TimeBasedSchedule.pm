package perfSONAR_PS::RegularTesting::Schedulers::TimeBasedSchedule;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use Moose;

extends 'perfSONAR_PS::RegularTesting::Schedulers::Base';

has 'time_slots' => (is => 'rw', isa => 'ArrayRef[Str]');

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { return "time_schedule" };

after 'check_configuration' => sub {
    my ($self) = @_;

    unless (@{ $self->time_slots } > 0) {
        die("'time_slot' parameters not specified");
    }

    foreach my $interval (@{ $self->time_slots }) {
        if ($interval =~ /^\*:(\d+)$/) {
            next if ($1 >= 0 and $1 <= 59);
        }

        if ($interval =~ /^(\d+):(\d+)$/) {
            next if ($1 >= 0 and $1 <= 24 and $2 >= 0 and $2 <= 59);
        }

        die("Invalid interval definition: $interval");
    }
};

override 'variable_map' => sub {
    return { "time_slots" => "time_slot" };
};


1;
