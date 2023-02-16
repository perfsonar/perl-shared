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

use perfSONAR_PS::Client::PScheduler::Task;

use Moose;

extends 'perfSONAR_PS::RegularTesting::Tests::BwctlBase';

has 'bwping_cmd' => (is => 'rw', isa => 'Str', default => '/usr/bin/bwping');
has 'tool' => (is => 'rw', isa => 'Str', default => 'ping');
has 'packet_interval' => (is => 'rw', isa => 'Int', default => 1);
has 'packet_size' => (is => 'rw', isa => 'Int', default => 1000);
has 'packet_count' => (is => 'rw', isa => 'Int', default => 10);
has 'packet_length' => (is => 'rw', isa => 'Int', default => 1000);
has 'packet_ttl' => (is => 'rw', isa => 'Int', );
has 'inter_packet_time' => (is => 'rw', isa => 'Num', default => 1.0);
has 'packet_tos_bits' => (is => 'rw', isa => 'Int');
#new pscheduler fields
has 'flowlabel' => (is => 'rw', isa => 'Int');
has 'flow_label' => (is => 'rw', isa => 'Int');
has 'hostnames' => (is => 'rw', isa => 'Bool');
has 'suppress_loopback' => (is => 'rw', isa => 'Bool');
has 'deadline' => (is => 'rw', isa => 'Int');
has 'timeout' => (is => 'rw', isa => 'Int');

my $logger = get_logger(__PACKAGE__);

#override 'type' => sub { "bwping" };
override 'type' => sub { "rtt" };

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
    push @cmd, ( '-t', $test_parameters->packet_ttl ) if $test_parameters->packet_ttl;
    push @cmd, ( '-l', $test_parameters->packet_length ) if $test_parameters->packet_length;
    push @cmd, ( '-i', $test_parameters->inter_packet_time ) if $test_parameters->inter_packet_time;

    push @cmd, '-E' unless $local_destination;

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
    $results->source($self->build_endpoint(address => $source, protocol => "icmp" ));
    $results->destination($self->build_endpoint(address => $destination, protocol => "icmp" ));

    $results->bidirectional(1);

    use Data::Dumper;
    $logger->debug("Results: ".Dumper($results->unparse));

    $results->packet_count($test_parameters->packet_count);
    $results->packet_size($test_parameters->packet_length);
    $results->packet_ttl($test_parameters->packet_ttl);
    $results->inter_packet_time($test_parameters->inter_packet_time);

    # Parse the bwctl output, and add it in
    my $bwctl_results = parse_bwctl_output({ stdout => $output });

    $results->source->address($bwctl_results->{results}->{source}) if $bwctl_results->{results}->{source};
    $results->destination->address($bwctl_results->{results}->{destination}) if $bwctl_results->{results}->{destination};

    my @pings = ();

    $results->packets_sent($bwctl_results->{results}->{sent}) if defined $bwctl_results->{results}->{sent};
    $results->packets_received($bwctl_results->{results}->{recv}) if defined $bwctl_results->{results}->{recv};

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

override 'build_pscheduler_task' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         url => 1,
                                         source => 1,
                                         destination => 1,
                                         destination_port => 0,
                                         local_destination => 1,
                                         force_ipv4 => 0,
                                         force_ipv6 => 0,
                                         test_parameters => 1,
                                         test => 1,
                                         source_node => 0,
                                         dest_node => 0,
                                      });
    my $psc_url           = $parameters->{url};
    my $source            = $parameters->{source};
    my $destination       = $parameters->{destination};
    my $local_destination = $parameters->{local_destination};
    my $force_ipv4        = $parameters->{force_ipv4};
    my $force_ipv6        = $parameters->{force_ipv6};
    my $test_parameters   = $parameters->{test_parameters};
    my $test              = $parameters->{test};
    my $schedule          = $test->schedule();
    my $source_node       = $parameters->{source_node};
    
    my $psc_task = new perfSONAR_PS::Client::PScheduler::Task(url => $psc_url);
    $psc_task->reference_param('description', $test->description()) if $test->description();
    foreach my $test_ref(@{$test->references()}){
        next if($test_ref->name() eq 'description' || $test_ref->name() eq 'created-by');
        $psc_task->reference_param($test_ref->name(), $test_ref->value());
    }
    
    #Test parameters
    my $psc_test_spec = {};
    #TODO: Support the options below
    #"flow_label":         { "$ref": "#/pScheduler/CardinalZero" },
    #"hostnames":         { "$ref": "#/pScheduler/Boolean" },
    #"suppress-loopback": { "$ref": "#/pScheduler/Boolean" },
    #"tos":               { "$ref": "#/pScheduler/Cardinal" },
    #"deadline":          { "$ref": "#/pScheduler/Duration" },
    #"timeout":           { "$ref": "#/pScheduler/Duration" },
    #tool?
    $psc_task->test_type('rtt');
    $psc_test_spec->{'source'} = $source if($source);
    $psc_test_spec->{'dest'} = $destination;
    $psc_test_spec->{'count'} = int($test_parameters->packet_count) if $test_parameters->packet_count;
    $psc_test_spec->{'length'} = int($test_parameters->packet_length) if $test_parameters->packet_length;
    $psc_test_spec->{'ttl'} = int($test_parameters->packet_ttl) if $test_parameters->packet_ttl;
    if($test_parameters->inter_packet_time ){
        if($test_parameters->inter_packet_time =~ /^\d+$/){
            #integer
            $psc_test_spec->{'interval'} = "PT" . $test_parameters->inter_packet_time  . "S";
        }else{
            #its a decimal. we must have a leading 0 to make sure pscheduler is happy
           $psc_test_spec->{'interval'} = "PT" . sprintf("%0.4f", $test_parameters->inter_packet_time)  . "S";
        }
    }
    $psc_test_spec->{'deadline'} = "PT" . $test_parameters->deadline  . "S" if $test_parameters->deadline;
    $psc_test_spec->{'timeout'} = "PT" . $test_parameters->timeout  . "S" if $test_parameters->timeout;
    $psc_test_spec->{'ip-tos'} = int($test_parameters->packet_tos_bits) if $test_parameters->packet_tos_bits;
    $psc_test_spec->{'flow-label'} = int($test_parameters->flow_label) if $test_parameters->flow_label;
    $psc_test_spec->{'hostnames'} = JSON::true if($test_parameters->{hostnames});
    $psc_test_spec->{'suppress-loopback'} = JSON::true if($test_parameters->{suppress_loopback});
    $psc_test_spec->{'ip-version'} = 4 if($force_ipv4 );
    $psc_test_spec->{'ip-version'} = 6 if($force_ipv6);
    $psc_test_spec->{'source-node'} = $source_node if($source_node);
    $psc_task->test_spec($psc_test_spec);
    
    #TODO: Support for more scheduling params
    if ($schedule->type eq "regular_intervals") {
        $self->psc_test_interval(schedule => $schedule, psc_task => $psc_task);
    }else{
        $logger->warn("Schedule type " . $schedule->type . " not currently supported. Skipping test.");
        return;
    }
    
    return $psc_task;    
    
};

override 'pscheduler_archive_type' => sub {
    return 'esmond/latency';
};

1;
