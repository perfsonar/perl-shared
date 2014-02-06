package perfSONAR_PS::RegularTesting::EventQueue::Event;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use Digest::MD5;
use Data::UUID;

use Moose;

has 'time'    => (is => 'rw', isa => 'Int');
has 'private' => (is => 'rw', isa => 'HashRef');

my $logger = get_logger(__PACKAGE__);

1;
