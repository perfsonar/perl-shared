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
    my $parameters = validate( @args, { test => 1, target => 1, test_parameters => 1, results => 1});
    my $results = $parameters->{results};

    return ($results->type eq "throughput");
};

override 'tool_name' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {test_parameters => 1, results => 1});
    my $results = $parameters->{results};
    my $test_parameters = $parameters->{test_parameters};

    if($test_parameters->type eq 'bwctl'){
        return 'bwctl/' . $results->tool;
    }elsif($test_parameters->type eq 'bwctl2'){
        return 'bwctl2/' . $results->tool;
    }
    
    #unrecognized so just return type directly
    return $test_parameters->type;

};

override 'event_types' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {test_parameters => 1, results => 1});
    my $results = $parameters->{results};
    my $test_parameters = $parameters->{test_parameters};
    
    my @event_types = (
        'failures',
        'throughput',
        'throughput-subintervals',
        );
    if($test_parameters->streams > 1){
        push @event_types, 'streams-throughput';
        push @event_types, 'streams-throughput-subintervals';
    }
    if($test_parameters->use_udp){
        push @event_types, 'packet-loss-rate';
        push @event_types, 'packet-count-lost';
        push @event_types, 'packet-count-sent';
    }
    elsif($test_parameters->tool eq 'iperf3') {
        push @event_types, 'packet-retransmits';
        push @event_types, 'packet-retransmits-subintervals';
        if($test_parameters->streams > 1){
            push @event_types, 'streams-packet-retransmits';
            push @event_types, 'streams-packet-retransmits-subintervals';
        }
    }

    return \@event_types;
};

override 'add_metadata_parameters' => sub{
    my ($self, @args) = @_;
    my $parameters = validate( @args, {test => 1, target => 1, test_parameters => 1, metadata => 1, results => 1});
    my $metadata = $parameters->{metadata};
    my $results = $parameters->{results};
    my $test = $parameters->{test};
    my $target = $parameters->{target};
    my $test_parameters = $parameters->{test_parameters};

    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'ip-transport-protocol', value => $results->source->protocol);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'time-duration', value => $test_parameters->duration);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'ip-tos', value => $test_parameters->packet_tos_bits);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'bw-buffer-size', value => $results->buffer_length);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'bw-parallel-streams', value => $test_parameters->streams);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'bw-target-bandwidth', value => $results->bandwidth_limit);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'tcp-window-size', value => $results->window_size);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'bw-ignore-first-seconds', value => $test_parameters->omit_interval);
    
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
    }elsif($event_type eq 'packet-retransmits-subintervals'){
        return $self->handle_packet_retransmits_subintervals(results=>$results);
    }elsif($event_type eq 'throughput'){
        return $self->handle_throughput(results=>$results);
    }elsif($event_type eq 'throughput-subintervals'){
        return $self->handle_throughput_subintervals(results=>$results);
    }elsif($event_type eq 'streams-packet-retransmits'){
        return $self->handle_streams_retransmits(results=>$results);
    }elsif($event_type eq 'streams-packet-retransmits-subintervals'){
        return $self->handle_streams_packet_retransmits_subintervals(results=>$results);
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

sub handle_subinterval_parameter {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1, parameter_name => 1});
    my $results = $parameters->{results};
    my $parameter_name = $parameters->{parameter_name};
    
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
            if(defined $interval->summary_results and $interval->summary_results->can($parameter_name)) {
                $tmpObj->{'val'} = $interval->summary_results->$parameter_name;
            }
            push @esmond_subintervals, $tmpObj;
        }
        return \@esmond_subintervals;
    }

    return;
}

sub handle_streams_subinterval_parameter {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1, parameter_name => 1});
    my $results = $parameters->{results};
    my $parameter_name = $parameters->{parameter_name};

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
                    'val' => $stream->$parameter_name
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
        
    return;
}

sub handle_streams_parameter{
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1, parameter_name => 1});
    my $results = $parameters->{results};
    my $parameter_name = $parameters->{parameter_name};

    if(defined $results->summary_results && scalar( @{$results->summary_results->streams} > 0)){
        my @stream = ();
        #make sure sorted by stream id
        foreach my $stream(sort {$a->stream_id cmp $b->stream_id} @{$results->summary_results->streams}){
             #don't even try to store really messed up stream
            return undef unless defined $stream->$parameter_name;
            push @stream, $stream->$parameter_name;
        }
        return \@stream;
    }

    return;
}


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

sub handle_packet_retransmits_subintervals(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};

    return $self->handle_subinterval_parameter(results => $results, parameter_name => "retransmits");
}

sub handle_streams_packet_retransmits_subintervals(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    return $self->handle_streams_subinterval_parameter(results => $results, parameter_name => "retransmits");
}

sub handle_throughput_subintervals(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    return $self->handle_subinterval_parameter(results => $results, parameter_name => "throughput");
}

sub handle_streams_throughput_subintervals(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    return $self->handle_streams_subinterval_parameter(results => $results, parameter_name => "throughput");
}

sub handle_streams_throughput(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    return $self->handle_streams_parameter(results => $results, parameter_name => "throughput");
}

sub handle_streams_retransmits(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    return $self->handle_streams_parameter(results => $results, parameter_name => "retransmits");

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
