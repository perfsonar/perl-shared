package perfSONAR_PS::RegularTesting::BindAddress;

use strict;
use warnings;

our $VERSION = 4.0;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use Digest::MD5;
use Data::UUID;
use perfSONAR_PS::RegularTesting::Reference;

use Moose;

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

has 'description'          => (is => 'rw', isa => 'Str');
has 'remote_address'              => (is => 'rw', isa => 'Str');
has 'bind_address'         => (is => 'rw', isa => 'Str');
has 'added_by_mesh'        => (is => 'rw', isa => 'Bool');

my $logger = get_logger(__PACKAGE__);

override 'parse' => sub {
    my ($class, $description, $strict) = @_;

    unless (ref($description) and ref($description) eq "HASH") {
        $description = { bind_address => $description };
    }

    return $class->SUPER::parse($description, $strict);
};

override 'unparse' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { });

    my $result = super();

    if ($result->{bind_address} and scalar(keys %$result) == 1) {
        $result = $result->{bind_address};
    }

    return $result;
};

1;
