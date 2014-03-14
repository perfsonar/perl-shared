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

use Moose;

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
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'sample-bucket-width', value => $results->histogram_bucket_size);
};

override 'add_datum' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {timestamp => 1, event_type => 1, results => 1});
    my $event_type = $parameters->{event_type};
    my $results = $parameters->{results};
    
    if($event_type eq 'packet-count-sent'){
        return $results->packets_sent;
    }elsif($event_type eq 'packet-count-lost'){
        return ($results->packets_sent - $results->packets_received);
    }elsif($event_type eq 'packet-loss-rate'){
        return {
            'numerator' => ($results->packets_sent - $results->packets_received),
            'denominator' => $results->packets_sent 
        };
    }else{
        return undef;
    }
};

1;
