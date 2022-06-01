package perfSONAR_PS::RegularTesting::Results::LatencyTestDatum;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Moose;

my $logger = get_logger(__PACKAGE__);

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

has 'sequence_number'   => (is => 'rw', isa => 'Int | Undef');
has 'ttl'               => (is => 'rw', isa => 'Int | Undef');
has 'delay'             => (is => 'rw', isa => 'Num | Undef');

no Moose;
__PACKAGE__->meta->make_immutable;

1;
