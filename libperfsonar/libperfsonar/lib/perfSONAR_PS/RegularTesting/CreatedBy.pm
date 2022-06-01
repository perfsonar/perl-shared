package perfSONAR_PS::RegularTesting::CreatedBy;

use strict;
use warnings;

our $VERSION = 4.0;

use Moose;

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

has 'agent_type' => (is => 'rw', isa => 'Str');
has 'name'       => (is => 'rw', isa => 'Str|Undef');
has 'uri'        => (is => 'rw', isa => 'Str|Undef');


1;
