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
 
extends 'perfSONAR_PS::RegularTesting::MeasurementArchives::EsmondBase';

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "esmond/ping" };

override 'accepts_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { results => 1, });
    my $results = $parameters->{results};

    return ($results->type eq "latency" and $results->bidirectional);
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

override 'add_metadata_parameters' => sub{
    my ($self, @args) = @_;
    my $parameters = validate( @args, {metadata => 1, results => 1});
    my $metadata = $parameters->{metadata};
    my $results = $parameters->{results};
    
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'ip-packet-size', value => $results->packet_size);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'ip-packet-interval', value => $results->inter_packet_time);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'ip-transport-protocol', value => $results->source->protocol);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'ip-ttl', value => $results->packet_ttl);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'sample-size', value => $results->packet_count);
    my $bucket_width = ($results->histogram_bucket_size ? $results->histogram_bucket_size : DEFAULT_BUCKET_WIDTH);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'sample-bucket-width', value => $bucket_width);
};

override 'add_datum' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {timestamp => 1, event_type => 1, results => 1});
    my $event_type = $parameters->{event_type};
    my $results = $parameters->{results};
    
    if($event_type eq 'histogram-rtt'){
        return $self->handle_histogram_rtt(results=>$results);
    }elsif($event_type eq 'histogram-ttl'){
        return $self->handle_histogram_ttl(results=>$results);
    }elsif($event_type eq 'packet-duplicates'){
        return $self->handle_duplicates(results=>$results);
    }elsif($event_type eq 'packet-count-sent'){
        return $self->handle_packets_sent(results=>$results);
    }elsif($event_type eq 'packet-count-lost'){
        return $self->handle_packets_lost(results=>$results);
    }elsif($event_type eq 'packet-loss-rate'){
        return $self->handle_packet_loss_rate(results=>$results);
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
    
    if(!defined $results->packets_sent){
        return undef;
    }
    
    return $results->packets_sent;
}

sub handle_packets_lost(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(!defined $results->packets_sent || !defined $results->packets_received){
        return undef;
    }
    
    return ($results->packets_sent - $results->packets_received);
}

sub handle_packet_loss_rate(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(!defined $results->packets_sent || !defined $results->packets_received){
        return undef;
    }
    
    return {
            'numerator' => ($results->packets_sent - $results->packets_received),
            'denominator' => $results->packets_sent 
        };
}


sub handle_duplicates(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(!$results->pings || @{$results->pings} == 0){
        return undef;
    }
    
    my $dups = 0;
    my %seen = ();
    foreach my $datum (@{ $results->pings }) {
        #copied from PinGER MA. better way to do this?
        if ($seen{$datum->sequence_number}) {
            $dups++;
        }
    }
    
    return $dups;
}

sub handle_histogram_ttl(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(!$results->pings || @{$results->pings} == 0){
        return undef;
    }
    
    my $hist = {};
    foreach my $datum (@{ $results->pings }) {
        $hist->{$datum->ttl}++ if(defined $datum->ttl);
    }
    
    return $hist;
}

sub handle_histogram_rtt(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(!$results->pings || @{$results->pings} == 0){
        return undef;
    }
    
    my $hist = {};
    foreach my $datum (@{ $results->pings }) {
        if(!defined $datum->delay){
            next;
        }
        my $bucket_width = ($results->histogram_bucket_size ? $results->histogram_bucket_size : DEFAULT_BUCKET_WIDTH);
        my $bucket = floor($datum->delay/$bucket_width);
        $hist->{$bucket}++;
    }
    
    return $hist;
}

sub handle_failures(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(!$results->errors || @{$results->errors} == 0){
        return undef;
    }
    
    my $err = join '--', @{$results->errors};
    return {'error' => $err};
}

1;
