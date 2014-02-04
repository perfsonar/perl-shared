package perfSONAR_PS::RegularTesting::Schedulers::Streaming;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use Moose;

extends 'perfSONAR_PS::RegularTesting::Schedulers::Base';

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { return "streaming" };

1;
