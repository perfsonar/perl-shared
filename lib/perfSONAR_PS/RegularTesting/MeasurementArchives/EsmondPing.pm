package perfSONAR_PS::RegularTesting::MeasurementArchives::EsmondPing;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Data::Dumper;
use JSON qw(from_json to_json);
use LWP;
use URI::Split qw(uri_split uri_join);
use POSIX qw/floor/;

use Moose;

use constant DEFAULT_BUCKET_WIDTH => .001;
 
extends 'perfSONAR_PS::RegularTesting::MeasurementArchives::EsmondLatency';

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "esmond/ping" };

override 'tool_name' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {test => 1, results => 1});
    my $results = $parameters->{results};
    my $test = $parameters->{test};

    if($test->parameters->type() eq 'bwping'){
        return 'bwctl/ping';
    }
    
    #unrecognized so just return type directly
    return $test->parameters->type();

};

override 'event_types' => sub {
    my ($self, @args) = @_;
    
    my @event_types = (
        'failures',
        'histogram-rtt',
        'histogram-ttl',
        'packet-duplicates',
        'packet-loss-rate',
        'packet-count-lost',
        'packet-count-sent');
    
    return \@event_types;
};

override 'default_summaries' => sub {
    my $self = shift;
    
    my @summaries = ();
    push @summaries, $self->create_summary_config(
        event_type=>'histogram-rtt', 
        summary_type  => 'statistics', 
        summary_window => '0');
    push @summaries, $self->create_summary_config(
        event_type=>'histogram-ttl', 
        summary_type  => 'statistics', 
        summary_window => '0');
    return @summaries;
};

1;
