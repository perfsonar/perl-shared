package perfSONAR_PS::RegularTesting::Results::TracerouteTest;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Moose;

my $logger = get_logger(__PACKAGE__);

use perfSONAR_PS::RegularTesting::Results::Endpoint;
use perfSONAR_PS::RegularTesting::Results::TracerouteTestHop;

extends 'perfSONAR_PS::RegularTesting::Results::Base';

has 'source'          => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Results::Endpoint', default => sub { return perfSONAR_PS::RegularTesting::Results::Endpoint->new() });
has 'destination'     => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Results::Endpoint', default => sub { return perfSONAR_PS::RegularTesting::Results::Endpoint->new() });

has 'packet_size'       => (is => 'rw', isa => 'Int | Undef');
has 'packet_first_ttl'  => (is => 'rw', isa => 'Int | Undef');
has 'packet_max_ttl'    => (is => 'rw', isa => 'Int | Undef');

has 'start_time'         => (is => 'rw', isa => 'DateTime');
has 'end_time'           => (is => 'rw', isa => 'DateTime');

has 'errors'          => (is => 'rw', isa => 'ArrayRef[Str]', default => sub { [] });

has 'path_mtu'           => (is => 'rw', isa => 'Int');
has 'hops'             => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::RegularTesting::Results::TracerouteTestHop]', default => sub { [] });

has 'raw_results'     => (is => 'rw', isa => 'Str');

has 'tool'            => (is => 'rw', isa => 'Str');

override 'type' => sub { return "traceroute" };

no Moose;
__PACKAGE__->meta->make_immutable;

1;
