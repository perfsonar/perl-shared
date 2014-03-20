package perfSONAR_PS::RegularTesting::MeasurementArchives::EsmondThroughput;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use POSIX qw/floor/;

use Moose;

use constant DEFAULT_BUCKET_WIDTH => .0001;
 
extends 'perfSONAR_PS::RegularTesting::MeasurementArchives::EsmondBase';

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "esmond/throughput" };

override 'accepts_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { test => 1, results => 1});
    my $results = $parameters->{results};

    return ($results->type eq "throughput");
};

override 'tool_name' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {test => 1, results => 1});
    my $results = $parameters->{results};
    my $test = $parameters->{test};

    if($test->parameters->type() eq 'bwctl'){
        return 'bwctl/' . $test->parameters->tool;
    }
    
    #unrecognized so just return type directly
    return $test->parameters->type();

};

override 'event_types' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {test => 1, results => 1});
    my $results = $parameters->{results};
    my $test = $parameters->{test};
    
    my @event_types = (
        'failures',
        'packet-loss-rate',
        'packet-count-lost',
        'packet-count-sent',
        'throughput',
        );
        
    return \@event_types;
};

override 'add_metadata_parameters' => sub{
    my ($self, @args) = @_;
    my $parameters = validate( @args, {test => 1, metadata => 1, results => 1});
    my $metadata = $parameters->{metadata};
    my $results = $parameters->{results};
    my $test = $parameters->{test};

    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'ip-transport-protocol', value => $results->source->protocol);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'time-duration', value => $test->parameters->duration);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'ip-tos', value => $test->parameters->packet_tos_bits);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'bw-buffer-size', value => $results->buffer_length);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'bw-parallel-streams', value => $test->parameters->streams);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'bw-target-bandwidth', value => $results->bandwidth_limit);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'tcp-window-size', value => $results->window_size);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'bw-ignore-first-seconds', value => $test->parameters->omit_interval);
    
};

override 'add_datum' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {timestamp => 1, event_type => 1, results => 1});
    my $event_type = $parameters->{event_type};
    my $results = $parameters->{results};
    
    if($event_type eq 'packet-count-sent'){
        return $results->packets_sent if($results->packets_sent);
    }elsif($event_type eq 'packet-count-lost'){
        #only set packets lost if iperf actually returned packets sent
        return $results->packets_lost if($results->packets_sent); 
    }elsif($event_type eq 'packet-loss-rate'){
        return $self->handle_packet_loss_rate(results=>$results);
    }elsif($event_type eq 'throughput'){
        return $self->handle_throughput(results=>$results);
    }elsif($event_type eq 'failures'){
        return $self->handle_failures(results=>$results);
    }else{
        return undef;
    }
};

sub handle_throughput(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(defined $results->throughput){
        return floor($results->throughput); #make an integer
    }
    
    return undef;
}

sub handle_packet_loss_rate(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if($results->packets_sent && defined $results->packets_lost){
        return {
            'numerator' => $results->packets_lost,
            'denominator' => $results->packets_sent 
        };
    }
    
    return undef;
}

1;
