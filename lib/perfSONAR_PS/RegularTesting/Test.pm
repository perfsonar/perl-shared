package perfSONAR_PS::RegularTesting::Test;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use Digest::MD5;
use Data::UUID;

use Moose;

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

has 'description'          => (is => 'rw', isa => 'Str');
has 'targets'              => (is => 'rw', isa => 'ArrayRef[Str]');
has 'local_address'        => (is => 'rw', isa => 'Str');
has 'parameters'           => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Tests::Base');
has 'schedule'             => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Schedulers::Base');
has 'measurement_archives' => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::RegularTesting::MeasurementArchives::Base]');

my $logger = get_logger(__PACKAGE__);

override 'variable_map' => sub {
    return { "targets" => "target", "measurement_archives" => "measurement_archive" };
};

sub validate_test {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         config => 1,
                                      });
    my $config = $parameters->{config};

    foreach my $target (@{ $self->targets }) {
        unless ($self->parameters->validate_target({ target => $target })) {
            die("Invalid target: $target");
        }
    }

    unless ($self->parameters->valid_schedule({ schedule => $self->schedule })) {
        die("Invalid schedule for test");
    }

    return;
}

sub init_test {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         config => 1,
                                      });
    my $config = $parameters->{config};

    return $self->parameters->init_test({
                                          test => $self,
                                          config => $config
                                       });
}

sub run_test {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         handle_results => 0,
                                      });
    my $handle_results = $parameters->{handle_results};

    return $self->parameters->run_test({
                                         test => $self,
                                         handle_results => $handle_results
                                      });
}

sub stop_test {
    my ($self) = @_;

    return $self->parameters->stop_test();
}

sub handles_own_scheduling {
    my ($self) = @_;

    return $self->parameters->handles_own_scheduling();
}

1;
