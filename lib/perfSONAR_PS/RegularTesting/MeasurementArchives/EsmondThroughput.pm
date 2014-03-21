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
        'packet-retransmits',
        'throughput',
        'throughput-subintervals',
        );
    if($test->parameters->streams > 1){
        push @event_types, 'streams-retransmits';
        push @event_types, 'streams-throughput';
        push @event_types, 'streams-throughput-subintervals';
    }
        
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
        return $self->handle_packets_sent(results=>$results);
    }elsif($event_type eq 'packet-count-lost'){
        return $self->handle_packets_lost(results=>$results);
    }elsif($event_type eq 'packet-loss-rate'){
        return $self->handle_packet_loss_rate(results=>$results);
    }elsif($event_type eq 'packet-retransmits'){
        return $self->handle_packet_retransmits(results=>$results);
    }elsif($event_type eq 'throughput'){
        return $self->handle_throughput(results=>$results);
    }elsif($event_type eq 'throughput-subintervals'){
        return $self->handle_throughput_subintervals(results=>$results);
    }elsif($event_type eq 'streams-retransmits'){
        return $self->handle_streams_retransmits(results=>$results);
    }elsif($event_type eq 'streams-throughput'){
        return $self->handle_streams_throughput(results=>$results);
    }elsif($event_type eq 'streams-throughput-subintervals'){
        return $self->handle_streams_throughput_subintervals(results=>$results);
    }elsif($event_type eq 'failures'){
        return $self->handle_failures(results=>$results);
    }else{
        return undef;
    }
};

sub handle_packets_sent(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(defined $results->summary_results &&
        $results->summary_results->summary_results &&
        $results->summary_results->summary_results->packets_sent){
        return $results->summary_results->summary_results->packets_sent;
    }
    
    return undef;
}

sub handle_packets_lost(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(defined $results->summary_results &&
        $results->summary_results->summary_results &&
        defined $results->summary_results->summary_results->packets_lost &&
        $results->summary_results->summary_results->packets_sent){#don't set unless we have packets sent
        return $results->summary_results->summary_results->packets_lost;
    }
    
    return undef;
}

sub handle_throughput(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(defined $results->summary_results &&
        $results->summary_results->summary_results &&
        defined $results->summary_results->summary_results->throughput){
        return floor($results->summary_results->summary_results->throughput); #make an integer
    }
    
    return undef;
}

sub handle_packet_retransmits(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(defined $results->summary_results &&
        $results->summary_results->summary_results &&
        defined $results->summary_results->summary_results->retransmits){
        return floor($results->summary_results->summary_results->retransmits); #make an integer
    }
    
    return undef;
}

sub handle_throughput_subintervals(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(defined $results->intervals && scalar( @{$results->intervals} > 0)){
        my @esmond_subintervals = ();
        #make sure sorted by start time
        foreach my $interval(sort {$a->start <=> $b->start} @{$results->intervals}){
             #don't even try to store really messed up subinterval
            return undef if(!defined $interval->start || !defined $interval->duration);
            my $tmpObj = {
                'start' => sprintf("%f", $interval->start), 
                'duration' => sprintf("%f", $interval->duration), 
                'val' => undef
                };
            if(defined $interval->summary_results){
                $tmpObj->{'val'} = $interval->summary_results->throughput;
            }
            push @esmond_subintervals, $tmpObj;
        }
        return \@esmond_subintervals;
    }
        
    return undef;
}

sub handle_streams_throughput_subintervals(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(defined $results->intervals && scalar( @{$results->intervals} > 0)){
        #build subintervals for each stream id
        my %stream_map = ();
        #make sure sorted by start time
        foreach my $interval(sort {$a->start <=> $b->start} @{$results->intervals}){
             #don't even try to store really messed up subinterval
            return undef if(!defined $interval->start || !defined $interval->duration);
            foreach my $stream(@{$interval->streams}){
                return undef if(!defined $stream->stream_id);
                if(!exists $stream_map{$stream->stream_id}){
                    $stream_map{$stream->stream_id} = [];
                }
                my $tmpObj = {
                    'start' => sprintf("%f", $interval->start), 
                    'duration' => sprintf("%f", $interval->duration), 
                    'val' => $stream->throughput
                };
                push @{$stream_map{$stream->stream_id}}, $tmpObj;
            }
        }
        
        #sort by stream id
        my @stream_ints = ();
        foreach my $stream_id(sort keys %stream_map){
            push @stream_ints, $stream_map{$stream_id};
        }
        return \@stream_ints;
    }
        
    return undef;
}

sub handle_streams_throughput(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(defined $results->summary_results && scalar( @{$results->summary_results->streams} > 0)){
        my @stream_throughputs = ();
        #make sure sorted by stream id
        foreach my $stream(sort {$a->stream_id <=> $b->stream_id} @{$results->summary_results->streams}){
             #don't even try to store really messed up stream
            return undef if(!defined $stream->throughput);
            push @stream_throughputs, $stream->throughput;
        }
        return \@stream_throughputs;
    }
        
    return undef;
}

sub handle_streams_retransmits(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(defined $results->summary_results && scalar( @{$results->summary_results->streams} > 0)){
        my @stream_retransmits = ();
        #make sure sorted by stream id
        foreach my $stream(sort {$a->stream_id <=> $b->stream_id} @{$results->summary_results->streams}){
             #don't even try to store really messed up stream
            return undef if(!defined $stream->retransmits);
            push @stream_retransmits, $stream->retransmits;
        }
        return \@stream_retransmits;
    }
        
    return undef;
}

sub handle_packet_loss_rate(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    my $sent = $self->handle_packets_sent(results=>$results);
    my $lost = $self->handle_packets_lost(results=>$results);
    if($sent && $lost){
        return {
            'numerator' => $lost,
            'denominator' => $sent
        };
    }
    
    return undef;
}

1;