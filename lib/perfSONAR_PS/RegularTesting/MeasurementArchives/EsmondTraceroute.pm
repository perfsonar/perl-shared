package perfSONAR_PS::RegularTesting::MeasurementArchives::EsmondTraceroute;

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

override 'type' => sub { "esmond/traceroute" };

override 'accepts_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { test => 1, target => 1, test_parameters => 1, results => 1});
    my $results = $parameters->{results};

    return ($results->type eq "traceroute");
};

override 'tool_name' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {test_parameters => 1, results => 1});
    my $results = $parameters->{results};
    my $test_parameters = $parameters->{test_parameters};

    if($test_parameters->type() eq 'bwtraceroute'){
        return 'bwctl/' . $results->tool;
    }elsif($test_parameters->type() eq 'bwtraceroute2'){
        return 'bwctl2/' . $results->tool;
    }
    
    #unrecognized so just return type directly
    return $test_parameters->type;

};

override 'event_types' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {test_parameters => 1, results => 1});
    my $results = $parameters->{results};
    my $test = $parameters->{test};
    
    my @event_types = (
        'failures',
        'packet-trace',
        'path-mtu'
        );
        
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
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'ip-packet-size', value => $test_parameters->packet_length);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'ip-tos', value => $test_parameters->packet_tos_bits);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'trace-first-ttl', value => $test_parameters->packet_first_ttl);
    $self->add_metadata_opt_parameter(metadata => $metadata, key => 'trace-max-ttl', value => $test_parameters->packet_max_ttl);
    
};

override 'add_datum' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {timestamp => 1, event_type => 1, results => 1});
    my $event_type = $parameters->{event_type};
    my $results = $parameters->{results};
    
    if($event_type eq 'packet-trace'){
        return $self->handle_packet_trace(results=>$results);
    }elsif($event_type eq 'path-mtu'){
        return $self->handle_path_mtu(results=>$results);
    }elsif($event_type eq 'failures'){
        return $self->handle_failures(results=>$results);
    }else{
        return undef;
    }
};

sub handle_packet_trace(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    if(defined $results->hops && scalar(@{ $results->hops }) > 0){
        my @packet_trace = ();
        my @sorted_hops = ();
        # sort by ttl (and query number if available) for convenience
        if(defined $results->hops->[0]->query_number){
            @sorted_hops = sort {$a->ttl <=> $b->ttl || $a->query_number <=> $b->query_number} @{ $results->hops };
        }else{
            @sorted_hops = sort {$a->ttl <=> $b->ttl} @{ $results->hops };
        }
        foreach my $hop (@sorted_hops) {
            next unless $hop->ttl;
            if ($hop->error){
                push @packet_trace, {
                    ttl => $hop->ttl,
                    query => $hop->query_number,
                    success => 0,
                    error_message => $hop->error,
                    rtt => undef,
                    ip => undef,
                    mtu => undef,
                };
            }else{
                push @packet_trace, {
                    ttl => $hop->ttl,
                    query => $hop->query_number,
                    success => 1,
                    error_message => undef,
                    rtt => $hop->delay,
                    ip => $hop->address,
                    mtu => $hop->path_mtu,
                };
            }
        }
        return \@packet_trace;
    }
    
    return undef;
}

sub handle_path_mtu(){
    my ($self, @args) = @_;
    my $parameters = validate( @args, {results => 1});
    my $results = $parameters->{results};
    
    return $results->path_mtu;
}

1;
