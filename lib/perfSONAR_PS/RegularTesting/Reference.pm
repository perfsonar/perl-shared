package perfSONAR_PS::RegularTesting::Reference;

use strict;
use warnings;

our $VERSION = 4.0;

use Moose;

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

has 'name'     => (is => 'rw', isa => 'Str');
has 'value'     => (is => 'rw', isa => 'Str');


1;
