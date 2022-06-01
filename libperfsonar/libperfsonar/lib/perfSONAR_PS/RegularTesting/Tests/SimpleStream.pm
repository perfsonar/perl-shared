package perfSONAR_PS::RegularTesting::Tests::SimpleStream;

use strict;
use warnings;

our $VERSION = 4.0;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Data::Validate::IP qw(is_ipv4);
use Data::Validate::Domain qw(is_hostname);
use Net::IP;

use perfSONAR_PS::RegularTesting::Utils qw(choose_endpoint_address parse_target);
use perfSONAR_PS::Utils::DNS qw(discover_source_address);
use perfSONAR_PS::Utils::Host qw(get_interface_addresses_by_type);


use Moose;

extends 'perfSONAR_PS::RegularTesting::Tests::PSchedulerBase';

has 'dawdle'        => (is => 'rw', isa => 'Int');
has 'fail'          => (is => 'rw', isa => 'Num');
has 'test_material' => (is => 'rw', isa => 'Str', default => sub{ "testing123" });
has 'timeout'       => (is => 'rw', isa => 'Int',);

   
my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "simplestream" };

override 'psc_test_spec' => sub {
   my ($self, @args) = @_;
   my $parameters = validate( @args, {
                                         source => 1,
                                         destination => 1,
                                         local_destination => 1,
                                         force_ipv4 => 0,
                                         force_ipv6 => 0,
                                         test_parameters => 1,
                                         test => 1,
                                      });
    my $source            = $parameters->{source};
    my $destination       = $parameters->{destination};
    my $local_destination = $parameters->{local_destination};
    my $force_ipv4        = $parameters->{force_ipv4};
    my $force_ipv6        = $parameters->{force_ipv6};
    my $test_parameters   = $parameters->{test_parameters};
    my $test              = $parameters->{test};
    
   
    my $psc_test_spec = {};
    $psc_test_spec->{'source'} = $source if($source);
    $psc_test_spec->{'dest'} = $destination if($destination);
    $psc_test_spec->{'dawdle'} = 'PT' . $test_parameters->dawdle . 'S' if(defined  $test_parameters->dawdle);
    $psc_test_spec->{'timeout'} = 'PT' . $test_parameters->timeout . 'S' if(defined $test_parameters->timeout);
    $psc_test_spec->{'fail'} = $test_parameters->fail + 0.0 if defined $test_parameters->fail;
    $psc_test_spec->{'test-material'} = $test_parameters->test_material if $test_parameters->test_material;   
        
    return $psc_test_spec;
    
};

1;
