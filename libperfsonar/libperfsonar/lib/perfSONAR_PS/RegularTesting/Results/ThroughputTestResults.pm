package perfSONAR_PS::RegularTesting::Results::ThroughputTestResults;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Moose;

my $logger = get_logger(__PACKAGE__);

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

has 'stream_id'       => (is => 'rw', isa => 'Str');

has 'jitter'          => (is => 'rw', isa => 'Num | Undef');
has 'packets_sent'    => (is => 'rw', isa => 'Int | Undef');
has 'packets_lost'    => (is => 'rw', isa => 'Int | Undef');
has 'snd_cwnd'       => (is => 'rw', isa => 'Int | Undef');
has 'retransmits'    => (is => 'rw', isa => 'Int | Undef');
has 'throughput'      => (is => 'rw', isa => 'Num');

no Moose;
__PACKAGE__->meta->make_immutable;

1;
