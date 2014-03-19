package perfSONAR_PS::RegularTesting::Results::ThroughputTestInterval;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Moose;

my $logger = get_logger(__PACKAGE__);

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

has 'start'           => (is => 'rw', isa => 'Num');
has 'duration'        => (is => 'rw', isa => 'Num');

has 'streams'         => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::RegularTesting::Results::ThroughputTestResults]');
has 'summary_results' => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Results::ThroughputTestResults');

no Moose;
__PACKAGE__->meta->make_immutable;

1;
