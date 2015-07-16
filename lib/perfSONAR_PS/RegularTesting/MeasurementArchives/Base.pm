package perfSONAR_PS::RegularTesting::MeasurementArchives::Base;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use Data::UUID;

use Moose;
use Class::MOP::Class;

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

my $logger = get_logger(__PACKAGE__);

has 'description'     => (is => 'rw', isa => 'Str');
has 'max_parallelism' => (is => 'rw', isa => 'Int', default => 5);

has 'queue_directory' => (is => 'rw', isa => 'Str');
has 'added_by_mesh'   => (is => 'rw', isa => 'Bool');

sub type {
    die("'type' needs to be overridden");
}

sub supports_parallelism {
    return 0;
}

sub nonce {
    die("'nonce' needs to be overridden");
}

sub accepts_results {
    die("'accepts_results' needs to be overridden");
}

sub store_results {
    die("'run_once' needs to be overridden");
}

1;
