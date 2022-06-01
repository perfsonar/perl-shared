package perfSONAR_PS::RegularTesting::Schedulers::Base;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Moose;
use Class::MOP::Class;

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

my $logger = get_logger(__PACKAGE__);

sub check_configuration {
    my ($self) = @_;

    return;
}

sub type {
    die("Type needs to be overridden");
}

1;
