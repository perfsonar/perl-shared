package perfSONAR_PS::RegularTesting::Tests::Base;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use perfSONAR_PS::RegularTesting::Utils qw(parse_target);

use Moose;
use Class::MOP::Class;

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

my $logger = get_logger(__PACKAGE__);

sub type {
    die("'type' needs to be overridden");
}

sub handles_own_scheduling {
    return;
}

sub valid_schedule {
    return 1;
}

sub init_test {
    die("'run_test' needs to be overridden");
}

sub run_test {
    die("'run_test' needs to be overridden");
}

sub stop_test {
    die("'stop_test' needs to be overridden");
}

sub valid_target {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         target => 0,
                                      });
    my $target = $parameters->{target};

    my $parsed_target = parse_target({ target => $target });
    unless ($parsed_target) {
        return;
    }

    return 1;
}

sub allows_bidirectional {
    return 0;
}

1;
