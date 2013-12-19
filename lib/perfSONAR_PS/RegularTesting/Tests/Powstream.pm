package perfSONAR_PS::RegularTesting::Tests::Powstream;

use strict;
use warnings;

our $VERSION = 3.4;

use IPC::Run qw( start pump );
use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use File::Temp qw(tempdir);
use File::Path qw(rmtree);

use POSIX ":sys_wait_h";

use Data::Validate::IP qw(is_ipv4);
use Data::Validate::Domain qw(is_hostname);
use Net::IP;

use perfSONAR_PS::RegularTesting::Utils qw(owptime2datetime);

use perfSONAR_PS::RegularTesting::Parsers::Owamp qw(parse_owamp_raw_file parse_owamp_summary_file);
use perfSONAR_PS::RegularTesting::Results::LatencyTest;
use perfSONAR_PS::RegularTesting::Results::LatencyTestDatum;

use Moose;

extends 'perfSONAR_PS::RegularTesting::Tests::Base';

has 'powstream_cmd'     => (is => 'rw', isa => 'Str', default => '/usr/bin/powstream');
has 'owstats_cmd'       => (is => 'rw', isa => 'Str', default => '/usr/bin/owstats');
has 'send_only'         => (is => 'rw', isa => 'Bool');
has 'receive_only'      => (is => 'rw', isa => 'Bool');
has 'force_ipv4'        => (is => 'rw', isa => 'Bool');
has 'force_ipv6'        => (is => 'rw', isa => 'Bool');
has 'resolution'        => (is => 'rw', isa => 'Int', default => 60);
has 'packet_length'     => (is => 'rw', isa => 'Int', default => 0);
has 'inter_packet_time' => (is => 'rw', isa => 'Num', default => 0.1);

has '_individual_tests' => (is => 'rw', isa => 'ArrayRef[HashRef]');

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "powstream" };

override 'allows_bidirectional' => sub { 1 };

override 'handles_own_scheduling' => sub { 1; };

override 'valid_schedule' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         schedule => 0,
                                      });
    my $schedule = $parameters->{schedule};

    return 1 if ($schedule->type eq "streaming");

    return;
};

sub get_individual_tests {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         test => 1,
                                      });
    my $test              = $parameters->{test};

    my @tests = ();
 
    # Build the set of set of tests that make up this bwctl test
    foreach my $target (@{ $test->targets }) {
        unless ($test->parameters->send_only) {
            push @tests, { target => $target, receiver => 1 };
        }
        unless ($test->parameters->receive_only) {
            push @tests, { target => $target, sender => 1 };
        }
    }

    return @tests;
}

override 'init_test' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         test   => 1,
                                         config => 1,
                                      });
    my $test   = $parameters->{test};
    my $config = $parameters->{config};

    my @individual_tests = $self->get_individual_tests({ test => $test });

    foreach my $test (@individual_tests) {
        eval {
            $test->{results_directory} = tempdir($config->test_result_directory."/owamp_XXXXX");
        };
        if ($@) {
            die("Couldn't create directory to store results: ".$@);
        }
    }

    $self->_individual_tests(\@individual_tests);

    return;
};

sub run_individual_test {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         test            => 1,
                                         individual_test => 1,
                                         handle_results  => 1,
                                      });
    my $test              = $parameters->{test};
    my $individual_test   = $parameters->{individual_test};
    my $handle_results    = $parameters->{handle_results};

    my ($powstream_process, $exiting);

    # Kill off the bwctl process we spawn if we get a SIGTERM
    $SIG{TERM} = $SIG{KILL} = sub {
        $logger->debug("Killing powstream test");
        eval { $powstream_process->kill_kill() } if ($powstream_process);
        $exiting = 1;
    };

    my $last_start_time;

    my %handled = ();
    while (1) {
        my $last_start_time = time;

        eval {
            last if $exiting;

            my $reverse_direction;

            # Calculate the total number of packets from the resolution
            my $packets = $self->resolution / $self->inter_packet_time;

            my @cmd = ();
            push @cmd, $self->powstream_cmd;
            push @cmd, '-4' if $self->force_ipv4;
            push @cmd, '-6' if $self->force_ipv6;
            push @cmd, ( '-p', '-d', $individual_test->{results_directory} );
            push @cmd, ( '-c', $packets );
            push @cmd, ( '-s', $self->packet_length ) if $self->packet_length;
            push @cmd, ( '-i', $self->inter_packet_time ) if $self->inter_packet_time;
            push @cmd, ( '-S', $test->local_address ) if $test->local_address;
            push @cmd, '-t' if $individual_test->{sender};
            push @cmd, $individual_test->{target};

            my ($out, $err);

            $powstream_process = start \@cmd, \undef, \$out, \$err;
            unless ($powstream_process) {
                die("Problem running command: $?");
            }

            my %summaries = ();

            while (1) {
                last if $exiting;

                pump $powstream_process;

                $logger->debug("IPC::Run::pump returned: out: ".$out." err: ".$err);

                $err = "";

                last if $exiting;

                my @files = split('\n', $out);
                foreach my $file (@files) {
                    ($file) = ($file =~ /(.*)/); # untaint the silly filename

                    next if $handled{$file};
    
                    my ($summary_id, $file_type);
                    if ($file =~ /(.*).(owp)$/) {
                        $summary_id = $1;
                        $file_type = $2;
                    }
                    elsif ($file =~ /(.*).(sum)$/) {
                        $summary_id = $1;
                        $file_type = $2;
                    }
                    else {
                        next;
                    }
    
                    $summaries{$summary_id} = {} unless $summaries{$summary_id};
                    $summaries{$summary_id}->{$file_type} = $file;

                    $handled{$file} = 1;
                }

                foreach my $summary_id (sort keys %summaries) {
                    unless ($summaries{$summary_id}->{sum} and 
                            $summaries{$summary_id}->{owp}) {
                        next;
                    }
    
                    last if $exiting;

                    my $source = $individual_test->{sender}?$test->local_address:$individual_test->{target};
                    my $destination = $individual_test->{receiver}?$individual_test->{target}:$test->local_address;

                    my $results = $self->build_results({
                                                         source => $source,
                                                         destination => $destination,
                                                         schedule => $test->schedule,
                                                         raw_file => $summaries{$summary_id}->{owp},
                                                         summary_file => $summaries{$summary_id}->{sum},
                                                      });
                    unless ($results) {
                        $logger->error("Problem parsing test results");
                        next;
                    }

                    eval {
                        $handle_results->(results => $results);
                    };
                    if ($@) {
                        $logger->error("Problem saving results: $results");
                        next;
                    }

                    unlink($summaries{$summary_id}->{owp});
                    unlink($summaries{$summary_id}->{sum});
                    delete($summaries{$summary_id});
                }
            }

            last if $exiting;
        };

        if ($@) {
            $logger->error("Problem running tests: $@");
            if ($powstream_process) {
                eval {
                    $powstream_process->kill_kill() 
                };
            }
        }

        last if $exiting;

        my $sleep_time;

        while(($sleep_time = ($last_start_time + 300) - time) > 0) {
            last if $exiting;

            sleep($sleep_time);
        }
    }

    return;
}

override 'run_test' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         test           => 1,
                                         handle_results => 1,
                                      });
    my $test              = $parameters->{test};
    my $handle_results    = $parameters->{handle_results};

    my %children = ();

    foreach my $individual_test (@{ $self->_individual_tests }) {
        my $pid = fork();

        if ($pid < 0) {
            $logger->error("Problem running tests: $@");
            $self->stop_test();
            return;
        }

        if ($pid == 0) {
            $self->run_individual_test({ individual_test => $individual_test, test => $test, handle_results => $handle_results });
            exit(0);
        }

        $individual_test->{pid} = $pid;

        $children{$pid} = $individual_test;
    }

    while(my $pid = waitpid(-1, 0) > 0) { }

    return;
};

override 'stop_test' => sub {
    my ($self) = @_;

    my %exited = ();

    foreach my $test (@{ $self->_individual_tests }) {
        if ($test->{pid}) {
            kill('TERM', $test->{pid});
        }
    }

    # Wait for the children to exit
    sleep(1);

    # Reap any children that exited
    my $pid;
    do {
        $pid = waitpid(-1, WNOHANG);
        $exited{$pid} = 1 if $pid > 0;
    } while $pid > 0;

    # Kill any remaining children more ... powerfully
    foreach my $test (@{ $self->_individual_tests }) {
        if ($test->{pid} and not $exited{$test->{pid}}) {
            kill('KILL', $test->{pid});
        }
    }

    # Remove the directories we created
    foreach my $test (@{ $self->_individual_tests }) {
        if (-d $test->{results_directory}) {
           eval {
               rmtree($test->{results_directory});
           };
           if ($@) {
               $logger->error("Couldn't remove: ".$test->{results_directory}.": ".$@);
           }
           else {
               $logger->debug("Removed: ".$test->{results_directory});
           }
        }
    }

    # Reap any remaining children before we exit
    do {
        $pid = waitpid(-1, WNOHANG);
    } while $pid > 0;
};

sub build_results {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         source => 1,
                                         destination => 1,
                                         schedule => 0,
                                         raw_file => 1,
                                         summary_file => 1,
                                      });
    my $source         = $parameters->{source};
    my $destination    = $parameters->{destination};
    my $schedule       = $parameters->{schedule};
    my $raw_file       = $parameters->{raw_file};
    my $summary_file   = $parameters->{summary_file};

    my $summary         = parse_owamp_summary_file({ summary_file => $summary_file });

    unless ($summary) {
        $logger->error("Problem parsing test results");
        return;
    }

    use Data::Dumper;
    #$logger->debug("Raw output: ".Dumper($raw));
    $logger->debug("Summary output: ".Dumper($summary));

    my $results = perfSONAR_PS::RegularTesting::Results::LatencyTest->new();

    # Fill in the information we know about the test
    $results->source($self->build_endpoint(address => $source, protocol => "udp" ));
    $results->destination($self->build_endpoint(address => $destination, protocol => "udp" ));

    $results->packet_count($self->resolution/$self->inter_packet_time);
    $results->packet_size($self->packet_length);
    $results->inter_packet_time($self->inter_packet_time);

    my $from_addr = $summary->{FROM_ADDR};
    my $to_addr = $summary->{TO_ADDR};

    $from_addr =~ s/%.*//;
    $to_addr =~ s/%.*//;

    $results->source->address($from_addr) if $from_addr;
    $results->destination->address($to_addr) if $to_addr;
    $results->start_time(owptime2datetime($summary->{START_TIME}));
    $results->end_time(owptime2datetime($summary->{END_TIME}));


    # Add the summarized results since adding the raw results is absurdly
    # expensive for powstream tests...
    $results->packets_sent($summary->{SENT});
    $results->packets_received($summary->{SENT} - $summary->{LOST});
    $results->duplicate_packets($summary->{DUPS});

    $results->histogram_bucket_size($summary->{BUCKET_WIDTH});

    my %delays = ();
    foreach my $bucket (keys %{ $summary->{BUCKETS} }) {
        $delays{$bucket * $summary->{BUCKET_WIDTH}} = $summary->{BUCKETS}->{$bucket};
    }
    $results->delay_histogram(\%delays);

    my %ttls = %{ $summary->{TTLBUCKETS} };
    $results->ttl_histogram(\%ttls);

    $results->raw_results("");

    # XXX: look into error conditions

    # XXX: I'm guessing the raw results should be the owp? I'm dunno
    $results->raw_results("");

    use Data::Dumper;
    $logger->debug("Results: ".Dumper($results->unparse));

    return $results;
};

sub build_endpoint {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         address  => 1,
                                         port     => 0,
                                         protocol => 0,
                                      });
    my $address        = $parameters->{address};
    my $port           = $parameters->{port};
    my $protocol       = $parameters->{protocol};

    my $endpoint = perfSONAR_PS::RegularTesting::Results::Endpoint->new();

    if ( is_ipv4( $address ) or 
         &Net::IP::ip_is_ipv6( $address ) ) {
        $endpoint->address($address);
    }
    else {
        $endpoint->hostname($address);
    }

    $endpoint->port($port) if $port;
    $endpoint->protocol($protocol) if $protocol;

    return $endpoint;
}

1;
