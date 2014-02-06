package perfSONAR_PS::RegularTesting::Config;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use Time::HiRes;
use Module::Load;

use perfSONAR_PS::RegularTesting::Test;

my $logger = get_logger(__PACKAGE__);

use Moose;

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

has 'tests'                        => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::RegularTesting::Test]', default => sub { [] });
has 'measurement_archives'         => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::RegularTesting::MeasurementArchives::Base]', default => sub { [] });
has 'test_result_directory'        => (is => 'rw', isa => 'Str', default => "/var/lib/perfsonar/regular_tests");

# Tests
use perfSONAR_PS::RegularTesting::Tests::Base;
use perfSONAR_PS::RegularTesting::Tests::Bwctl;
use perfSONAR_PS::RegularTesting::Tests::Bwping;
use perfSONAR_PS::RegularTesting::Tests::BwpingOwamp;
use perfSONAR_PS::RegularTesting::Tests::Bwtraceroute;
use perfSONAR_PS::RegularTesting::Tests::Powstream;

# Measurement Archives
use perfSONAR_PS::RegularTesting::MeasurementArchives::Base;
use perfSONAR_PS::RegularTesting::MeasurementArchives::Null;
use perfSONAR_PS::RegularTesting::MeasurementArchives::perfSONARBUOYBwctl;
use perfSONAR_PS::RegularTesting::MeasurementArchives::PingER;
use perfSONAR_PS::RegularTesting::MeasurementArchives::TracerouteMA;
use perfSONAR_PS::RegularTesting::MeasurementArchives::perfSONARBUOYOwamp;

# Schedulers
use perfSONAR_PS::RegularTesting::Schedulers::Base;
use perfSONAR_PS::RegularTesting::Schedulers::RegularInterval;
use perfSONAR_PS::RegularTesting::Schedulers::Streaming;

override 'variable_map' => sub {
    return { "tests" => "test", "measurement_archives" => "measurement_archive" };
};

sub init {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { config => 1 });
    my $config = $parameters->{config};

    return (0, "");
}

1;
