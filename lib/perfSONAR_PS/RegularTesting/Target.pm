package perfSONAR_PS::RegularTesting::Target;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use Digest::MD5;
use Data::UUID;
use perfSONAR_PS::RegularTesting::Reference;

use Moose;

extends 'perfSONAR_PS::RegularTesting::Utils::SerializableObject';

has 'description'          => (is => 'rw', isa => 'Str');
has 'address'              => (is => 'rw', isa => 'Str');
has 'references'            => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::RegularTesting::Reference]');
has 'override_parameters'  => (is => 'rw', isa => 'perfSONAR_PS::RegularTesting::Tests::Base');

my $logger = get_logger(__PACKAGE__);

override 'variable_map' => sub {
    return { "references" => "reference" };
};

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
