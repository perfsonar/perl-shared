package perfSONAR_PS::RegularTesting::Results::ThroughputTest;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Moose;

my $logger = get_logger(__PACKAGE__);

use perfSONAR_PS::RegularTesting::Results::Endpoint;

extends 'perfSONAR_PS::RegularTesting::Results::Base';

has 'source'          => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Results::Endpoint', default => sub { return perfSONAR_PS::RegularTesting::Results::Endpoint->new() });
has 'destination'     => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Results::Endpoint', default => sub { return perfSONAR_PS::RegularTesting::Results::Endpoint->new() });

has 'window_size'     => (is => 'rw', isa => 'Int | Undef');
has 'bandwidth_limit' => (is => 'rw', isa => 'Int | Undef');
has 'buffer_length'   => (is => 'rw', isa => 'Int | Undef');
has 'time_duration'   => (is => 'rw', isa => 'Int');
has 'streams'         => (is => 'rw', isa => 'Int | Undef');
has 'tos_bits'        => (is => 'rw', isa => 'Int | Undef');

has 'start_time'         => (is => 'rw', isa => 'DateTime');
has 'end_time'           => (is => 'rw', isa => 'DateTime');

has 'errors'          => (is => 'rw', isa => 'ArrayRef[Str]', default => sub { [] });

has 'jitter'          => (is => 'rw', isa => 'Num | Undef');
has 'packets_sent'    => (is => 'rw', isa => 'Int | Undef');
has 'packets_lost'    => (is => 'rw', isa => 'Int | Undef');
has 'throughput'      => (is => 'rw', isa => 'Num');

has 'raw_results'     => (is => 'rw', isa => 'Str');

override 'type' => sub { return "throughput" };

no Moose;
__PACKAGE__->meta->make_immutable;

1;
