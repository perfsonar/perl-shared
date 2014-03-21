package perfSONAR_PS::RegularTesting::MeasurementArchives::Null;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use JSON;

use Moose;

extends 'perfSONAR_PS::RegularTesting::MeasurementArchives::Base';

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "null" };

override 'nonce' => sub {
    my ($self) = @_;

    return "null";
};

override 'accepts_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { test => 1, target => 1, test_parameters => 1, results => 1});

    return 1;
};

override 'store_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         test    => 1,
                                         target  => 1,
                                         test_parameters => 1,
                                         results => 1,
                                      });
    my $results = $parameters->{results};

    $logger->debug("Got results: ".JSON->new->pretty->encode($results->unparse));

    return (0, "");
};

1;
