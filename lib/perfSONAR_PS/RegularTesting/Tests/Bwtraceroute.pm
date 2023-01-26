package perfSONAR_PS::RegularTesting::Tests::Bwtraceroute;

use strict;
use warnings;

our $VERSION = 3.4;

use IPC::Run qw( start pump );
use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use File::Temp qw(tempdir);

use perfSONAR_PS::RegularTesting::Results::TracerouteTest;

use perfSONAR_PS::RegularTesting::Parsers::Bwctl qw(parse_bwctl_output);

use Moose;

extends 'perfSONAR_PS::RegularTesting::Tests::BwctlBase';

has 'bwtraceroute_cmd' => (is => 'rw', isa => 'Str', default => '/usr/bin/bwtraceroute');
has 'tool' => (is => 'rw', isa => 'Str');
has 'packet_length' => (is => 'rw', isa => 'Int');
has 'packet_first_ttl' => (is => 'rw', isa => 'Int', );
has 'packet_max_ttl' => (is => 'rw', isa => 'Int', );
has 'packet_tos_bits' => (is => 'rw', isa => 'Int');
#new pscheduler fields
has 'algorithm' => (is => 'rw', isa => 'Str');
has 'as' => (is => 'rw', isa => 'Bool');
has 'fragment' => (is => 'rw', isa => 'Bool');
has 'hostnames' => (is => 'rw', isa => 'Bool');
has 'probe_type' => (is => 'rw', isa => 'Str');
has 'queries' => (is => 'rw', isa => 'Int');
has 'sendwait' => (is => 'rw', isa => 'Int');
has 'wait' => (is => 'rw', isa => 'Int');
            
my $logger = get_logger(__PACKAGE__);

#override 'type' => sub { "bwtraceroute" };
override 'type' => sub { "trace" };

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

    my $results = perfSONAR_PS::RegularTesting::Results::TracerouteTest->new();

    # Fill in the information we know about the test
    $results->source($self->build_endpoint(address => $source, protocol => "icmp" ));
    $results->destination($self->build_endpoint(address => $destination, protocol => "icmp" ));

    $results->packet_size($test_parameters->packet_length);
    $results->packet_first_ttl($test_parameters->packet_max_ttl);
    $results->packet_max_ttl($test_parameters->packet_max_ttl);

    # Parse the bwctl output, and add it in
    my $bwctl_results = parse_bwctl_output({ stdout => $output });

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
    my $destination_port       = $parameters->{destination_port};
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
    $psc_task->test_type('trace');
    $psc_test_spec->{'source'} = $source if($source);
    $psc_test_spec->{'dest'} = $destination;
    if($test->parameters->tool){
        my @tools = split ',', $test->parameters->tool;
        foreach my $tool(@tools){
            if($tool eq 'traceroute'){
                $psc_task->add_requested_tool('bwctltraceroute');
                $psc_task->add_requested_tool('traceroute');
            }elsif($tool eq 'tracepath'){
                $psc_task->add_requested_tool('bwctltracepath');
                $psc_task->add_requested_tool('tracepath');
            }else{
                $psc_task->add_requested_tool($tool);
            }
        }
    }
    $psc_test_spec->{'dest-port'} = int($destination_port) if($destination_port);
    $psc_test_spec->{'length'} = int($test_parameters->packet_length) if $test_parameters->packet_length;
    $psc_test_spec->{'first-ttl'} = int($test_parameters->packet_first_ttl) if $test_parameters->packet_first_ttl;
    $psc_test_spec->{'hops'} = int($test_parameters->packet_max_ttl) if $test_parameters->packet_max_ttl;
    $psc_test_spec->{'algorithm'} = $test_parameters->algorithm if $test_parameters->algorithm;
    $psc_test_spec->{'as'} = JSON::true if $test_parameters->as;
    $psc_test_spec->{'fragment'} = JSON::true if $test_parameters->fragment;
    $psc_test_spec->{'hostnames'} = JSON::true if $test_parameters->hostnames;
    $psc_test_spec->{'probe-type'} = $test_parameters->probe_type if $test_parameters->probe_type;
    $psc_test_spec->{'queries'} = int($test_parameters->queries) if $test_parameters->queries;
    $psc_test_spec->{'ip-tos'} = int($test_parameters->packet_tos_bits) if $test_parameters->packet_tos_bits;
    $psc_test_spec->{'sendwait'} = "PT" . $test_parameters->sendwait . "S" if $test_parameters->sendwait;
    $psc_test_spec->{'wait'} = "PT" . $test_parameters->sendwait . "S" if $test_parameters->sendwait;
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
    return 'esmond/traceroute';
};

sub TO_JSON {
    return { %{ shift() } };
};


1;
