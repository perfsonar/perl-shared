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

has 'queue_directory' => (is => 'rw', isa => 'Str');

sub type {
    return "";
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
