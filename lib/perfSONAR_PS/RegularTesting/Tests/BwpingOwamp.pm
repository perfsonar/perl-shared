package perfSONAR_PS::RegularTesting::Tests::BwpingOwamp;

use strict;
use warnings;

our $VERSION = 3.4;

use IPC::Run qw( start pump );
use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use File::Temp qw(tempdir);

use perfSONAR_PS::RegularTesting::Results::LatencyTest;
use perfSONAR_PS::RegularTesting::Results::LatencyTestDatum;

use perfSONAR_PS::RegularTesting::Parsers::Bwctl qw(parse_bwctl_output);

use Moose;

extends 'perfSONAR_PS::RegularTesting::Tests::BwctlBase';

has 'bwping_cmd' => (is => 'rw', isa => 'Str', default => '/usr/bin/bwping');
has 'tool' => (is => 'rw', isa => 'Str', default => 'owamp');
has 'packet_count' => (is => 'rw', isa => 'Int', default => 100);
has 'packet_length' => (is => 'rw', isa => 'Int', default => 1000);
has 'inter_packet_time' => (is => 'rw', isa => 'Num', default => 0.1);

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "bwping/owamp" };

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
    my $local_destination = $parameters->{local_destination};
    my $results_directory = $parameters->{results_directory};
    my $test_parameters   = $parameters->{test_parameters};
    my $schedule          = $parameters->{schedule};

    my @cmd = ();
    push @cmd, $test_parameters->bwping_cmd;

    # Add the parameters from the parent class
    push @cmd, super();

    push @cmd, ( '-N', $test_parameters->packet_count ) if $test_parameters->packet_count;
    push @cmd, ( '-l', $test_parameters->packet_length ) if $test_parameters->packet_length;
    push @cmd, ( '-i', $test_parameters->inter_packet_time ) if $test_parameters->inter_packet_time;

    push @cmd, ( '--flip' ) if $local_destination;

    push @cmd, ( '--no_endpoint' );

    # Get the raw output
    push @cmd, ( '-y', 'R' );

    return @cmd;
};

override 'build_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         source => 1,
                                         destination => 1,
                                         test_parameters => 1,
                                         schedule => 0,
                                         output => 1,
                                      });
    my $source          = $parameters->{source};
    my $destination     = $parameters->{destination};
    my $test_parameters = $parameters->{test_parameters};
    my $schedule        = $parameters->{schedule};
    my $output          = $parameters->{output};

    my $results = perfSONAR_PS::RegularTesting::Results::LatencyTest->new();

    # Fill in the information we know about the test
    $results->source($self->build_endpoint(address => $source, protocol => "udp" ));
    $results->destination($self->build_endpoint(address => $destination, protocol => "udp" ));

    $results->packet_count($test_parameters->packet_count);
    $results->packet_size($test_parameters->packet_length);
    $results->inter_packet_time($test_parameters->inter_packet_time);

    # Parse the bwctl output, and add it in
    my $bwctl_results = parse_bwctl_output({ stdout => $output });

    $results->source->address($bwctl_results->{sender_address}) if $bwctl_results->{sender_address};
    $results->destination->address($bwctl_results->{receiver_address}) if $bwctl_results->{receiver_address};

    my @pings = ();
    
    if ($bwctl_results->{results}->{pings}) {
        my $max_err = undef;
        foreach my $ping (@{ $bwctl_results->{results}->{pings} }) {
            my $datum = perfSONAR_PS::RegularTesting::Results::LatencyTestDatum->new();
            $datum->sequence_number($ping->{sequence_number}) if defined $ping->{sequence_number};
            $datum->ttl($ping->{ttl}) if defined $ping->{ttl};
            #convert to milliseconds from seconds.
            $datum->delay($ping->{delay} * 1000) if defined $ping->{delay};
            if(!defined $max_err || $max_err < $ping->{max_error}){
                $max_err = $ping->{max_error};
            }
            push @pings, $datum;
        }
        $results->time_error_estimate($max_err);
    }

    $results->pings(\@pings);

    if ($bwctl_results->{error}) {
        push @{ $results->errors }, $bwctl_results->{error};
    }

    if ($bwctl_results->{results}->{error}) {
        push @{ $results->errors }, $bwctl_results->{results}->{error};
    }

    $logger->debug("BWCTL Results: ".Dumper($bwctl_results));

    $results->start_time($bwctl_results->{start_time});
    $results->end_time($bwctl_results->{end_time});

    $results->raw_results($output);

    use Data::Dumper;
    $logger->debug("Results: ".Dumper($results->unparse));

    return $results;
};

1;
