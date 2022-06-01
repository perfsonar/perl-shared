package perfSONAR_PS::RegularTesting::Results::Endpoint;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Moose;

my $logger = get_logger(__PACKAGE__);

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

has 'hostname' => (is => 'rw', isa => 'Str | Undef');
has 'address'  => (is => 'rw', isa => 'Str');
has 'port'     => (is => 'rw', isa => 'Int | Undef');
has 'protocol' => (is => 'rw', isa => 'Str');

no Moose;
__PACKAGE__->meta->make_immutable;

1;
