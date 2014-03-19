package perfSONAR_PS::RegularTesting::Results::TracerouteTestHop;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Moose;

my $logger = get_logger(__PACKAGE__);

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

has 'ttl'               => (is => 'rw', isa => 'Int');
has 'address'           => (is => 'rw', isa => 'Str');
has 'query_number'      => (is => 'rw', isa => 'Int');
has 'delay'             => (is => 'rw', isa => 'Num');
has 'error'             => (is => 'rw', isa => 'Str');
has 'path_mtu'          => (is => 'rw', isa => 'Int');

no Moose;
__PACKAGE__->meta->make_immutable;

1;
