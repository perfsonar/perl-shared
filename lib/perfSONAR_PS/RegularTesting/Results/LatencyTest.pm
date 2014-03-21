package perfSONAR_PS::RegularTesting::Results::LatencyTest;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Moose;

my $logger = get_logger(__PACKAGE__);

use perfSONAR_PS::RegularTesting::Results::Endpoint;
use perfSONAR_PS::RegularTesting::Results::LatencyTestDatum;

extends 'perfSONAR_PS::RegularTesting::Results::Base';

has 'source'             => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Results::Endpoint', default => sub { return perfSONAR_PS::RegularTesting::Results::Endpoint->new() });
has 'destination'        => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Results::Endpoint', default => sub { return perfSONAR_PS::RegularTesting::Results::Endpoint->new() });

has 'packet_count'       => (is => 'rw', isa => 'Int | Undef');
has 'packet_size'        => (is => 'rw', isa => 'Int | Undef');
has 'packet_ttl'         => (is => 'rw', isa => 'Int | Undef');
has 'inter_packet_time'  => (is => 'rw', isa => 'Num | Undef');

has 'bidirectional'      => (is => 'rw', isa => 'Bool', default => 0);

has 'start_time'         => (is => 'rw', isa => 'DateTime');
has 'end_time'           => (is => 'rw', isa => 'DateTime');

has 'errors'             => (is => 'rw', isa => 'ArrayRef[Str]', default => sub { [] });

has 'delay_histogram'    => (is => 'rw', isa => 'HashRef[Int]', default => sub { {} });
has 'histogram_bucket_size' => (is => 'rw', isa => 'Num');
has 'ttl_histogram'      => (is => 'rw', isa => 'HashRef[Int]', default => sub { {} });

has 'packets_sent'       => (is => 'rw', isa => 'Int');
has 'packets_received'   => (is => 'rw', isa => 'Int');
has 'duplicate_packets'  => (is => 'rw', isa => 'Int');
has 'time_error_estimate'=> (is => 'rw', isa => 'Num | Undef');

has 'pings'              => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::RegularTesting::Results::LatencyTestDatum]', default => sub { [] });

has 'raw_results'        => (is => 'rw', isa => 'Str');

override 'type'          => sub { return "latency" };

no Moose;
__PACKAGE__->meta->make_immutable;

1;
