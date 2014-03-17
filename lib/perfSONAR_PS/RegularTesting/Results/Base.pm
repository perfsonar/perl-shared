package perfSONAR_PS::RegularTesting::Results::Base;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Moose;

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

my $logger = get_logger(__PACKAGE__);

sub type {
    die("'type' needs to be overridden");
}

1;
