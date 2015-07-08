package perfSONAR_PS::RegularTesting::Tests::Bwtraceroute2;

use strict;
use warnings;

our $VERSION = 3.4;

use IPC::Run qw( start pump );
use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use File::Temp qw(tempdir);
use Data::Dumper;

use perfSONAR_PS::RegularTesting::Results::TracerouteTest;

use perfSONAR_PS::RegularTesting::Parsers::Bwctl2 qw(parse_bwctl2_output);

use Moose;

extends 'perfSONAR_PS::RegularTesting::Tests::Bwctl2Base';

has 'bwtraceroute_cmd' => (is => 'rw', isa => 'Str', default => '/usr/bin/bwtraceroute2');
has 'tool' => (is => 'rw', isa => 'Str', default => 'tracepath,traceroute');
has 'packet_length' => (is => 'rw', isa => 'Int');
has 'packet_first_ttl' => (is => 'rw', isa => 'Int', );
has 'packet_max_ttl' => (is => 'rw', isa => 'Int', );
has 'packet_tos_bits' => (is => 'rw', isa => 'Int');

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "bwtraceroute2" };

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
    push @cmd, $test_parameters->bwtraceroute_cmd;

    # Add the parameters from the parent class
    push @cmd, super();

    # XXX: need to set interpacket time

    push @cmd, ( '-F', $test_parameters->packet_first_ttl ) if $test_parameters->packet_first_ttl;
    push @cmd, ( '-M', $test_parameters->packet_max_ttl ) if $test_parameters->packet_max_ttl;
    push @cmd, ( '-l', $test_parameters->packet_length ) if $test_parameters->packet_length;

    # Prevent traceroute from doing DNS lookups since Net::Traceroute doesn't
    # like them...
    push @cmd, ( '-y', 'a' );
    
    #Don;t support this yet, should add it back when we do
    #push @cmd, '-E' unless $local_destination;

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

    my $results = perfSONAR_PS::RegularTesting::Results::TracerouteTest->new();

    # Fill in the information we know about the test
    $results->source($self->build_endpoint(address => $source, protocol => "icmp" ));
    $results->destination($self->build_endpoint(address => $destination, protocol => "icmp" ));

    $results->packet_size($test_parameters->packet_length);
    $results->packet_first_ttl($test_parameters->packet_max_ttl);
    $results->packet_max_ttl($test_parameters->packet_max_ttl);

    # Parse the bwctl output, and add it in
    my $bwctl_results = parse_bwctl2_output({ stdout => $output });

    $logger->debug("BWCTL Results: ".Dumper($bwctl_results));

    $results->source->address($bwctl_results->{sender_address}) if $bwctl_results->{sender_address};
    $results->destination->address($bwctl_results->{receiver_address}) if $bwctl_results->{receiver_address};
    $results->tool($bwctl_results->{tool}) if $bwctl_results->{tool};
    
    my @hops = ();
    if ($bwctl_results->{results}->{hops}) {
        foreach my $hop_desc (@{ $bwctl_results->{results}->{hops} }) {
            my $hop = perfSONAR_PS::RegularTesting::Results::TracerouteTestHop->new();
            $hop->ttl($hop_desc->{ttl}) if defined $hop_desc->{ttl};
            $hop->address($hop_desc->{hop}) if defined $hop_desc->{hop};
            $hop->query_number($hop_desc->{queryNum}) if defined $hop_desc->{queryNum};
            $hop->delay($hop_desc->{delay}) if defined $hop_desc->{delay};
            $hop->error($hop_desc->{error}) if defined $hop_desc->{error};
            $hop->path_mtu($hop_desc->{path_mtu}) if defined $hop_desc->{path_mtu};
            push @hops, $hop;
        }
    }

    $results->path_mtu($bwctl_results->{results}->{path_mtu}) if defined $bwctl_results->{results}->{path_mtu};

    $results->hops(\@hops);

    if ($bwctl_results->{error}) {
        push @{ $results->errors }, $bwctl_results->{error};
    }

    if ($bwctl_results->{results}->{error}) {
        push @{ $results->errors }, $bwctl_results->{results}->{error};
    }

    $results->start_time($bwctl_results->{start_time});
    #end time may not be set if authz failure or similar, so set to start
    $results->end_time($bwctl_results->{end_time} ? $bwctl_results->{end_time} : $bwctl_results->{start_time});

    $results->raw_results($output);

    $logger->debug("Results: ".Dumper($results->unparse));

    return $results;
};

1;
