package perfSONAR_PS::RegularTesting::Target;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use Digest::MD5;
use Data::UUID;

use Moose;

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

has 'description'          => (is => 'rw', isa => 'Str');
has 'address'              => (is => 'rw', isa => 'Str');

has 'override_parameters'  => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Tests::Base');

my $logger = get_logger(__PACKAGE__);

override 'parse' => sub {
    my ($class, $description, $strict) = @_;

    unless (ref($description) and ref($description) eq "HASH") {
        $description = { address => $description };
    }

    return $class->SUPER::parse($description, $strict);
};

override 'unparse' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { });

    my $result = super();

    if ($result->{address} and scalar(keys %$result) == 1) {
        $result = $result->{address};
    }

    return $result;
};

1;
