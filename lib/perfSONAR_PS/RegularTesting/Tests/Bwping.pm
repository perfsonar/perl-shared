package perfSONAR_PS::RegularTesting::Tests::Bwping;

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
has 'tool' => (is => 'rw', isa => 'Str', default => 'ping');
has 'packet_count' => (is => 'rw', isa => 'Int', default => 10);
has 'packet_length' => (is => 'rw', isa => 'Int', default => 1000);
has 'packet_ttl' => (is => 'rw', isa => 'Int', );
has 'inter_packet_time' => (is => 'rw', isa => 'Num', default => 1.0);

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "bwping" };

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
    push @cmd, $self->bwping_cmd;

    # Add the parameters from the parent class
    push @cmd, super();

    # XXX: need to set interpacket time

    push @cmd, ( '-N', $self->packet_count ) if $self->packet_count;
    push @cmd, ( '-t', $self->packet_ttl ) if $self->packet_ttl;
    push @cmd, ( '-l', $self->packet_length ) if $self->packet_length;

    push @cmd, '-E';

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

    my $results = perfSONAR_PS::RegularTesting::Results::LatencyTest->new();

    # Fill in the information we know about the test
    $results->source($self->build_endpoint(address => $source, protocol => "icmp" ));
    $results->destination($self->build_endpoint(address => $destination, protocol => "icmp" ));

    $results->bidirectional(1);

    use Data::Dumper;
    $logger->debug("Results: ".Dumper($results->unparse));

    $results->packet_count($self->packet_count);
    $results->packet_size($self->packet_length);
    $results->packet_ttl($self->packet_ttl);
    $results->inter_packet_time($self->inter_packet_time);

    # Parse the bwctl output, and add it in
    my $bwctl_results = parse_bwctl_output({ stdout => $output, tool_type => $self->tool });

    $results->source->address($bwctl_results->{results}->{source}) if $bwctl_results->{results}->{source};
    $results->destination->address($bwctl_results->{results}->{destination}) if $bwctl_results->{results}->{destination};

    my @pings = ();

    $results->packets_sent($bwctl_results->{results}->{sent});
    $results->packets_received($bwctl_results->{results}->{recv});

    if ($bwctl_results->{results}->{pings}) {
        foreach my $ping (@{ $bwctl_results->{results}->{pings} }) {
            my $datum = perfSONAR_PS::RegularTesting::Results::LatencyTestDatum->new();
            $datum->sequence_number($ping->{seq}) if defined $ping->{seq};
            $datum->ttl($ping->{ttl}) if defined $ping->{ttl};
            $datum->delay($ping->{delay}) if defined $ping->{delay};
            push @pings, $datum;
        }
    }

    $results->pings(\@pings);

    if ($bwctl_results->{error}) {
        push @{ $results->errors }, $bwctl_results->{error};
    }

    if ($bwctl_results->{results}->{error}) {
        push @{ $results->errors }, $bwctl_results->{results}->{error};
    }

    $results->start_time($bwctl_results->{start_time});
    $results->end_time($bwctl_results->{end_time});

    $results->raw_results($output);

    use Data::Dumper;
    $logger->debug("Results: ".Dumper($results->unparse));

    return $results;
};

1;
