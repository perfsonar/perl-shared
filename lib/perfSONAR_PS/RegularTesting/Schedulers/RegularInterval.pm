package perfSONAR_PS::RegularTesting::Schedulers::RegularInterval;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use Moose;

extends 'perfSONAR_PS::RegularTesting::Schedulers::Base';

has 'interval' => (is => 'rw', isa => 'Int');

has 'random_start_percentage' => (is => 'rw', isa => 'Int');

has '_next_run_time'  => (is => 'rw', isa => 'Int');

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { return "regular_intervals" };

after 'check_configuration' => sub {
    my ($self) = @_;

    unless ($self->interval) {
        die("'interval' not specified");
    }
};

sub calculate_next_run_time {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { });

    unless ($self->_next_run_time) {
        $self->_next_run_time(time);
    }
    else {
        my $runtime = $self->_next_run_time + $self->interval;

        $self->_next_run_time($runtime);
    }

    return $self->_next_run_time;
}

1;
