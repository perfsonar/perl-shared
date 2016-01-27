package perfSONAR_PS::RegularTesting::Tests::Bwctl;

use strict;
use warnings;

our $VERSION = 3.4;

use IPC::Run qw( start pump );
use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use File::Temp qw(tempdir);

use perfSONAR_PS::RegularTesting::Parsers::Bwctl qw(parse_bwctl_output fill_iperf_data fill_iperf3_data);

use Moose;

extends 'perfSONAR_PS::RegularTesting::Tests::BwctlBase';

has 'bwctl_cmd' => (is => 'rw', isa => 'Str', default => '/usr/bin/bwctl');
has 'tool' => (is => 'rw', isa => 'Str', default => 'iperf');
has 'use_udp' => (is => 'rw', isa => 'Bool', default => 0);
has 'streams' => (is => 'rw', isa => 'Int', default => 1);
has 'duration' => (is => 'rw', isa => 'Int', default => 10);
has 'omit_interval' => (is => 'rw', isa => 'Int');
has 'udp_bandwidth' => (is => 'rw', isa => 'Int');
has 'buffer_length' => (is => 'rw', isa => 'Int');
has 'packet_tos_bits' => (is => 'rw', isa => 'Int');
has 'window_size'   => (is => 'rw', isa => 'Int');

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "bwctl" };

override 'build_cmd' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         source => 1,
                                         destination => 1,
                                         local_destination => 1,
                                         force_ipv4 => 0,
                                         force_ipv6 => 0,
                                         results_directory => 1,
                                         test_parameters => 1,
                                         schedule => 0,
                                      });
    my $source            = $parameters->{source};
    my $destination       = $parameters->{destination};
    my $results_directory = $parameters->{results_directory};
    my $test_parameters   = $parameters->{test_parameters};
    my $schedule          = $parameters->{schedule};

    my @cmd = ();
    push @cmd, $test_parameters->bwctl_cmd;

    # Add the parameters from the parent class
    push @cmd, super();

    if($test_parameters->use_udp){
        push @cmd, '-u';
        push @cmd, ( '-b', $test_parameters->udp_bandwidth ) if $test_parameters->udp_bandwidth;
    }
    push @cmd, ( '-P', $test_parameters->streams ) if $test_parameters->streams;
    push @cmd, ( '-t', $test_parameters->duration ) if $test_parameters->duration;
    push @cmd, ( '-O', $test_parameters->omit_interval ) if $test_parameters->omit_interval;
    push @cmd, ( '-l', $test_parameters->buffer_length ) if $test_parameters->buffer_length;
    push @cmd, ( '-w', $test_parameters->window_size ) if $test_parameters->window_size;

    # Set a default reporting interval
    push @cmd, ( '-i', '1' );

    # Have the tool use the most parsable format
    push @cmd, ( '--parsable' );

    return @cmd;
};

override 'build_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         source => 1,
                                         destination => 1,
                                         test_parameters => 0,
                                         schedule => 0,
                                         output => 1,
                                      });
    my $source          = $parameters->{source};
    my $destination     = $parameters->{destination};
    my $test_parameters = $parameters->{test_parameters};
    my $schedule        = $parameters->{schedule};
    my $output          = $parameters->{output};

    my $results = perfSONAR_PS::RegularTesting::Results::ThroughputTest->new();

    my $protocol;
    if ($test_parameters->use_udp) {
        $protocol = "udp";
    }
    else {
        $protocol = "tcp";
    }

    # Fill in the information we know about the test
    $results->source($self->build_endpoint(address => $source, protocol => $protocol));
    $results->destination($self->build_endpoint(address => $destination, protocol => $protocol));

    $results->protocol($protocol);
    $results->streams($test_parameters->streams);
    $results->time_duration($test_parameters->duration);
    $results->bandwidth_limit($test_parameters->udp_bandwidth) if $test_parameters->udp_bandwidth;
    $results->buffer_length($test_parameters->buffer_length) if $test_parameters->buffer_length;

    # Add in the raw output
    $results->raw_results($output);

    # Parse the bwctl output, and add it in
    my $bwctl_results = parse_bwctl_output({ stdout => $output });

    # Fill in the data that came directly from BWCTL itself
    $results->source->address($bwctl_results->{sender_address}) if $bwctl_results->{sender_address};
    $results->destination->address($bwctl_results->{receiver_address}) if $bwctl_results->{receiver_address};
    $results->tool($bwctl_results->{tool});
    
    push @{ $results->errors }, $bwctl_results->{error} if ($bwctl_results->{error});

    $results->start_time($bwctl_results->{start_time});
    $results->end_time($bwctl_results->{end_time});

    # Fill in the data that came from the tool itself
    if ($bwctl_results->{tool} eq "iperf") {
        fill_iperf_data({ results_obj => $results, results => $bwctl_results->{results} });
    }
    elsif ($bwctl_results->{tool} eq "iperf3") {
        fill_iperf3_data({ results_obj => $results, results => $bwctl_results->{results} });
    }
    else {
        push @{ $results->errors }, "Unknown tool type: ".$bwctl_results->{tool};
    }

    use Data::Dumper;
    $logger->debug("Build Results: ".Dumper($results->unparse));

    return $results;
};

1;
