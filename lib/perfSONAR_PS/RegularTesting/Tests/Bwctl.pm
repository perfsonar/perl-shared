package perfSONAR_PS::RegularTesting::Tests::Bwctl;

use strict;
use warnings;

our $VERSION = 3.4;

use IPC::Run qw( start pump );
use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use File::Temp qw(tempdir);

use perfSONAR_PS::RegularTesting::Parsers::Bwctl qw(parse_bwctl_output);

use Moose;

extends 'perfSONAR_PS::RegularTesting::Tests::BwctlBase';

has 'bwctl_cmd' => (is => 'rw', isa => 'Str', default => '/usr/bin/bwctl');
has 'tool' => (is => 'rw', isa => 'Str', default => 'iperf');
has 'use_udp' => (is => 'rw', isa => 'Bool', default => 0);
has 'streams' => (is => 'rw', isa => 'Int', default => 1);
has 'duration' => (is => 'rw', isa => 'Int', default => 10);
has 'udp_bandwidth' => (is => 'rw', isa => 'Int');
has 'buffer_length' => (is => 'rw', isa => 'Int');

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "bwctl" };

override 'build_cmd' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         source => 1,
                                         destination => 1,
                                         results_directory => 1,
                                         schedule => 0,
                                      });
    my $source            = $parameters->{source};
    my $destination       = $parameters->{destination};
    my $results_directory = $parameters->{results_directory};
    my $schedule          = $parameters->{schedule};

    my @cmd = ();
    push @cmd, $self->bwctl_cmd;

    # Add the parameters from the parent class
    push @cmd, super();

    push @cmd, '-u' if $self->use_udp;
    push @cmd, ( '-P', $self->streams ) if $self->streams;
    push @cmd, ( '-t', $self->duration ) if $self->duration;
    push @cmd, ( '-b', $self->udp_bandwidth ) if $self->udp_bandwidth;
    push @cmd, ( '-l', $self->buffer_length ) if $self->buffer_length;

    push @cmd, ('-y', 'J') if ($self->tool eq "iperf3");

    return @cmd;
};

override 'build_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         source => 1,
                                         destination => 1,
                                         schedule => 0,
                                         output => 1,
                                      });
    my $source         = $parameters->{source};
    my $destination    = $parameters->{destination};
    my $schedule       = $parameters->{schedule};
    my $output         = $parameters->{output};

    my $results = perfSONAR_PS::RegularTesting::Results::ThroughputTest->new();

    my $protocol;
    if ($self->use_udp) {
        $protocol = "udp";
    }
    else {
        $protocol = "tcp";
    }

    # Fill in the information we know about the test
    $results->source($self->build_endpoint(address => $source, protocol => $protocol));
    $results->destination($self->build_endpoint(address => $destination, protocol => $protocol));

    $results->streams($self->streams);
    $results->time_duration($self->duration);
    $results->bandwidth_limit($self->udp_bandwidth) if $self->udp_bandwidth;
    $results->buffer_length($self->buffer_length) if $self->buffer_length;

    # Add in the raw output
    $results->raw_results($output);

    # Parse the bwctl output, and add it in
    my $bwctl_results = parse_bwctl_output({ stdout => $output, tool_type => $self->tool });

    use Data::Dumper;
    $logger->debug("BWCTL Results: ".Dumper($bwctl_results));

    # Fill in the data that came directly from BWCTL itself
    $results->source->address($bwctl_results->{sender_address}) if $bwctl_results->{sender_address};
    $results->destination->address($bwctl_results->{receiver_address}) if $bwctl_results->{receiver_address};

    push @{ $results->errors }, $bwctl_results->{error} if ($bwctl_results->{error});

    $results->start_time($bwctl_results->{start_time});
    $results->end_time($bwctl_results->{end_time});

    # Fill in the data that came from the tool itself
    if ($self->tool eq "iperf") {
        $self->fill_iperf_data({ results_obj => $results, results => $bwctl_results->{results} });
    }
    elsif ($self->tool eq "iperf3") {
        $self->fill_iperf3_data({ results_obj => $results, results => $bwctl_results->{results} });
    }
    else {
        push @{ $results->errors }, "Unknown tool type: ".$self->tool;
    }

    return $results;
};

sub fill_iperf_data {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         results_obj => 1,
                                         results => 1,
                                      });
    my $results_obj    = $parameters->{results_obj};
    my $results        = $parameters->{results};

    push @{ $results_obj->errors }, $results->{error} if ($results->{error});

    $results_obj->throughput($results->{throughput}) if $results->{throughput};
    $results_obj->jitter($results->{jitter}) if $results->{jitter};
    $results_obj->packets_sent($results->{packets_sent}) if defined $results->{packets_sent};
    $results_obj->packets_lost($results->{packets_lost}) if defined $results->{packets_lost};

    return;
}

sub fill_iperf3_data {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         results_obj => 1,
                                         results => 1,
                                      });
    my $results_obj    = $parameters->{results_obj};
    my $results        = $parameters->{results};

    push @{ $results_obj->errors }, $results->{error} if ($results->{error});

    $results_obj->throughput($results->{end}->{sum_received}->{bits_per_second}) if $results->{end}->{sum_received}->{bits_per_second};
    $results_obj->jitter($results->{end}->{sum_received}->{jitter_ms}) if $results->{end}->{sum_received}->{jitter_ms};
    $results_obj->packets_sent($results->{end}->{sum_received}->{total_packets}) if defined $results->{end}->{sum_received}->{total_packets};
    $results_obj->packets_lost($results->{end}->{sum_received}->{lost_packets}) if defined $results->{end}->{sum_received}->{lost_packets};

    return;
}

1;
