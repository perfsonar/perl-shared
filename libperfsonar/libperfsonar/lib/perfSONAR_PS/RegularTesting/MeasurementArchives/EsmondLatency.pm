package perfSONAR_PS::RegularTesting::MeasurementArchives::EsmondLatency;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Moose;
 
extends 'perfSONAR_PS::RegularTesting::MeasurementArchives::EsmondBase';

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "esmond/latency" };

override 'accepts_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { test => 1, target => 1, test_parameters => 1, results => 1});
    my $results = $parameters->{results};

    return ($results->type eq "latency");
};

override 'tool_name' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {test_parameters => 1, results => 1});
    my $results = $parameters->{results};
    my $test_parameters = $parameters->{test_parameters};

    if($test_parameters->type eq 'bwping'){
        return 'bwctl/ping';
    }elsif($test_parameters->type eq 'powstream'){
        return 'powstream';
    }elsif($test_parameters->type eq 'bwping/owamp'){
        return 'bwctl/owping';
    }elsif($test_parameters->type eq 'bwping2/owamp'){
        return 'bwctl2/owping';
    }elsif($test_parameters->type eq 'bwping2'){
        return 'bwctl2/ping';
    }
    
    #unrecognized so just return type directly
    return $test_parameters->type();

};

override 'event_types' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {test_parameters => 1, results => 1});
    my $results = $parameters->{results};
    my $test_parameters = $parameters->{test_parameters};
    
    my @event_types = (
        'failures',
        'packet-count-sent',
        );
    if($results->bidirectional){
        push  @event_types, 'histogram-rtt';
        push  @event_types, 'histogram-ttl-reverse';
        push  @event_types, 'packet-duplicates-bidir';
        push  @event_types, 'packet-loss-rate-bidir';
        push  @event_types, 'packet-count-lost-bidir';
        push  @event_types, 'packet-reorders-bidir';
    }else{
        push  @event_types, 'histogram-owdelay';
        push  @event_types, 'histogram-ttl';
        push  @event_types, 'packet-duplicates';
        push  @event_types, 'packet-loss-rate';
        push  @event_types, 'packet-count-lost';
        if($test_parameters->type ne 'powstream'){
            push  @event_types, 'packet-reorders';
        }else{
            push  @event_types, 'time-error-estimates';
        }
    }
    return \@event_types;
};

override 'default_summaries' => sub {
    my $self = shift;
    
    my @summaries = ();
    push @summaries, $self->create_summary_config(
        event_type=>'histogram-owdelay', 
        summary_type  => 'statistics', 
        summary_window => '0');
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

override 'add_metadata_parameters' => sub{
    my ($self, @args) = @_;
    my $parameters = validate( @args, {test => 1, target => 1, test_parameters => 1, metadata => 1, results => 1});
    my $metadata = $parameters->{metadata};
    my $results = $parameters->{results};
    my $test = $parameters->{test};
    my $test_parameters = $parameters->{test_parameters};
    
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'ip-packet-size', value => $results->packet_size);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'time-probe-interval', value => $results->inter_packet_time);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'ip-transport-protocol', value => $results->source->protocol);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'ip-ttl', value => $results->packet_ttl);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'sample-size', value => $results->packet_count);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'sample-bucket-width', value => $results->histogram_bucket_size) if(defined $results->histogram_bucket_size );
    if($results->packet_count && $results->inter_packet_time && !$results->bidirectional){
        $self->add_metadata_opt_parameter(metadata => $metadata, key => 'time-duration', value => ($results->packet_count * $results->inter_packet_time));
    }
    if($test_parameters->type eq 'bwping'){
        $self->add_metadata_opt_parameter(metadata => $metadata, key => 'ip-tos', value => $test_parameters->packet_tos_bits);
    }
};

override 'add_datum' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {timestamp => 1, event_type => 1, results => 1});
    my $event_type = $parameters->{event_type};
    my $results = $parameters->{results};
    
    if($event_type eq 'histogram-owdelay' || $event_type eq 'histogram-rtt'){
        return $self->handle_histogram_delay(results=>$results);
    }elsif($event_type eq 'histogram-ttl' || $event_type eq 'histogram-ttl-reverse'){
        return $self->handle_histogram_ttl(results=>$results);
    }elsif($event_type eq 'packet-duplicates' || $event_type eq 'packet-duplicates-bidir'){
        return $self->handle_duplicates(results=>$results);
    }elsif($event_type eq 'packet-count-sent'){
        return $self->handle_packets_sent(results=>$results);
    }elsif($event_type eq 'packet-count-lost' || $event_type eq 'packet-count-lost-bidir'){
        return $self->handle_packets_lost(results=>$results);
    }elsif($event_type eq 'packet-loss-rate' || $event_type eq 'packet-loss-rate-bidir'){
        return $self->handle_packet_loss_rate(results=>$results);
    }elsif($event_type eq 'packet-reorders' || $event_type eq 'packet-reorders-bidir'){
        return $self->handle_packet_reorders(results=>$results);
    }elsif($event_type eq 'time-error-estimates'){
        return $self->handle_time_error_estimates(results=>$results);
    }elsif($event_type eq 'failures'){
        return $self->handle_failures(results=>$results);
    }else{
        return undef;
    }
};

sub parse_ping {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    my $dups = 0;
    my $sent = 0;
    my $recv = 0;
    my $oops = 0;
    
    my %seen = ();
    my $prev_datum = undef;
    foreach my $datum (@{ $results->pings }) {
        if ($seen{$datum->sequence_number}) {
            $dups++;
            next;
        }
        $sent++;
        
        unless ($datum->delay) {
            # Skip lost packets
            next;
        }

        $seen{$datum->sequence_number} = 1;
        $recv++;
        if ($prev_datum and $datum->sequence_number < $prev_datum->sequence_number) {
            $oops++;
        }
        
        $prev_datum = $datum;
    }
    
    return ($dups, $sent, $recv, $oops);
}

sub handle_packets_sent(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(defined $results->packets_sent){
        return $results->packets_sent;
    }elsif (scalar(@{ $results->pings }) > 0) {    
        my ($dups, $sent, $recv, $oops) = $self->parse_ping(results => $results);
        return $sent;
    }
    
    return undef;
}

sub handle_packets_lost(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(defined $results->packets_sent && defined $results->packets_received){
        return ($results->packets_sent - $results->packets_received);
    }elsif (scalar(@{ $results->pings }) > 0) {    
        my ($dups, $sent, $recv, $oops) = $self->parse_ping(results => $results);
        return ($sent - $recv);
    }
    
    return undef;
}

sub handle_packet_loss_rate(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if($results->packets_sent && defined $results->packets_received){
        return {
            'numerator' => ($results->packets_sent - $results->packets_received),
            'denominator' => $results->packets_sent 
        };
    }elsif (scalar(@{ $results->pings }) > 0) {    
        my ($dups, $sent, $recv, $oops) = $self->parse_ping(results => $results);
        return {
            'numerator' => ($sent - $recv),
            'denominator' => $sent
        } if($sent > 0);
    }
    
    return undef;
}

sub handle_duplicates(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(defined $results->duplicate_packets){
        return $results->duplicate_packets;
    }elsif (scalar(@{ $results->pings }) > 0) {    
        my ($dups, $sent, $recv, $oops) = $self->parse_ping(results => $results);
        return $dups;
    }
    
    return undef;
}

sub handle_packet_reorders(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if (scalar(@{ $results->pings }) > 0) {    
        my ($dups, $sent, $recv, $oops) = $self->parse_ping(results => $results);
        return $oops;
    }
    
    return undef;
}

sub handle_histogram_ttl(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    my $hist = {};
    if (scalar(@{ $results->pings }) > 0) {
        foreach my $datum (@{ $results->pings }) {
            $hist->{$datum->ttl}++ if(defined $datum->ttl);
        }
    }else{
        $hist = $results->ttl_histogram;
    }
    
    if(scalar(keys %{$hist}) == 0){
        $hist = undef;
    }
    
    return $hist;
}

sub handle_histogram_delay(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    my $hist = {};
    if (scalar(@{ $results->pings }) > 0) {
        foreach my $datum (@{ $results->pings }) {
            if(!defined $datum->delay){
                next;
            }
            $hist->{sprintf("%.2f", $datum->delay)}++;
        }
    }else{
        $hist = $results->delay_histogram;
    }
    
    #don't store an empty object
    if(scalar(keys %{$hist}) == 0){
        $hist = undef;
    }
    
    return $hist;
}

sub handle_time_error_estimates(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(defined $results->time_error_estimate){
        return sprintf("%f", $results->time_error_estimate);
    }
    
    return undef;
}

1;
